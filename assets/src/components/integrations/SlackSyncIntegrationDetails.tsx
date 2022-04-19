import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Twemoji} from 'react-emoji-render';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {
  notification,
  Alert,
  Button,
  Card,
  Container,
  Divider,
  Input,
  Paragraph,
  Popconfirm,
  Switch,
  Tag,
  Text,
  Title,
  Tooltip,
} from '../common';
import {ArrowLeftOutlined, CheckCircleOutlined, PlusOutlined} from '../icons';
import * as API from '../../api';
import {
  Account,
  Inbox,
  SlackAuthorization,
  SlackAuthorizationSettings,
} from '../../types';
import {
  getSlackAuthUrl,
  getSlackRedirectUrl,
  parseSlackAuthState,
} from './support';
import logger from '../../logger';

const IntegrationSettings = ({
  settings,
  onUpdateSettings,
}: {
  settings: SlackAuthorizationSettings;
  onUpdateSettings: (updates: Partial<SlackAuthorizationSettings>) => void;
}) => {
  const handleUpdateSyncAllThreads = (isEnabled: boolean) =>
    onUpdateSettings({sync_all_incoming_threads: isEnabled});
  const handleUpdateSyncByEmoji = (isEnabled: boolean) =>
    onUpdateSettings({sync_by_emoji_tagging: isEnabled});

  return (
    <>
      <Box mb={3}>
        <label>Sync all incoming messages</label>
        <Box>
          <Switch
            checked={settings.sync_all_incoming_threads}
            size="small"
            onChange={handleUpdateSyncAllThreads}
          />
        </Box>
      </Box>

      <Box mb={3}>
        <label>
          Sync messages tagged with <Twemoji text=":eyes:" /> emoji
        </label>
        <Box>
          <Switch
            checked={settings.sync_by_emoji_tagging}
            size="small"
            onChange={handleUpdateSyncByEmoji}
          />
        </Box>
      </Box>

      <Box mb={3}>
        <label>Trigger emoji</label>
        <Tooltip
          title="The ability to configure this field is coming soon!"
          placement="right"
        >
          <Flex sx={{maxWidth: 240, alignItems: 'center'}}>
            <Input type="text" value=":eyes:" disabled />

            <Box mx={2}>
              <Twemoji text=":eyes:" />
            </Box>
          </Flex>
        </Tooltip>
      </Box>
    </>
  );
};

const IntegrationDetails = ({
  authorization,
  onUpdateSettings,
}: {
  authorization: SlackAuthorization | null;
  onUpdateSettings: (
    authorization: SlackAuthorization,
    updates: Partial<SlackAuthorizationSettings>
  ) => void;
}) => {
  if (!authorization) {
    return (
      <Box mb={4}>
        <Title level={4}>Integration settings</Title>
        <Card
          sx={{
            p: 3,
            bg: 'rgb(245, 245, 245)',
          }}
        >
          <Box mb={3}>
            <label>Channel</label>
            <Box>
              <Text type="secondary">Not connected</Text>
            </Box>
          </Box>
          <Box mb={3}>
            <label>Team</label>
            <Box>
              <Text type="secondary">Not connected</Text>
            </Box>
          </Box>
          <Box mb={3}>
            <label>Slack configuration URL</label>
            <Box>
              <Text type="secondary">Not connected</Text>
            </Box>
          </Box>
        </Card>
      </Box>
    );
  }

  const {
    channel,
    settings,
    team_name: teamName,
    configuration_url: configurationUrl,
  } = authorization;

  return (
    <Box mb={4}>
      <Title level={4}>Settings for {teamName}</Title>

      <Card
        sx={{
          p: 3,
          bg: 'rgb(245, 245, 245)',
        }}
      >
        <Box mb={3}>
          <label>Channel</label>
          <Box>
            <Text strong>{channel}</Text>
          </Box>
        </Box>
        <Box mb={3}>
          <label>Team</label>
          <Box>
            <Text strong>{teamName}</Text>
          </Box>
        </Box>
        <Box mb={3}>
          <label>Slack configuration URL</label>
          <Box>
            <Text>
              <a
                href={configurationUrl}
                target="_blank"
                rel="noopener noreferrer"
              >
                {configurationUrl}
              </a>
            </Text>
          </Box>
        </Box>

        {settings && (
          <>
            <Divider />

            <IntegrationSettings
              settings={settings}
              onUpdateSettings={(updates) =>
                onUpdateSettings(authorization, updates)
              }
            />
          </>
        )}
      </Card>
    </Box>
  );
};

type Props = RouteComponentProps<{inbox_id?: string}>;
type State = {
  status: 'loading' | 'success' | 'error';
  account: Account | null;
  authorizations: Array<SlackAuthorization>;
  inbox: Inbox | null;
  selectedSlackAuthorization: SlackAuthorization | null;
  error: any;
};

class SlackSyncIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    account: null,
    authorizations: [],
    inbox: null,
    selectedSlackAuthorization: null,
    error: null,
  };

  async componentDidMount() {
    try {
      const {location, history, match} = this.props;
      const {search} = location;
      const {inbox_id: inboxId} = match.params;
      const q = qs.parse(search);
      const code = q.code ? String(q.code) : null;

      if (code) {
        await this.authorize(code, q);

        const redirect = inboxId
          ? `/inboxes/${inboxId}/integrations/slack/support`
          : `/integrations/slack/support`;

        history.push(redirect);
      }

      if (inboxId) {
        const inbox = await API.fetchInbox(inboxId);

        this.setState({inbox});
      }

      this.fetchSlackAuthorizations();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchSlackAuthorizations = async () => {
    try {
      const {inbox_id: inboxId} = this.props.match.params;
      const authorizations = await API.listSlackAuthorizations('support', {
        inbox_id: inboxId,
      });
      const account = await API.fetchAccountInfo();
      const {selectedSlackAuthorization} = this.state;
      const [selected = null] = authorizations;

      this.setState({
        account,
        authorizations,
        selectedSlackAuthorization:
          authorizations.find(
            (auth) => auth.id === selectedSlackAuthorization?.id
          ) || selected,
        status: 'success',
      });
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  };

  authorize = async (code: string, query: any) => {
    const state = query.state ? String(query.state) : '';
    const {type = 'support', inboxId} = parseSlackAuthState(state);

    if (!code) {
      return null;
    }

    return API.authorizeSlackIntegration({
      code,
      type,
      inbox_id: inboxId,
      redirect_url: getSlackRedirectUrl(),
    })
      .then((result) => logger.debug('Successfully authorized Slack:', result))
      .catch((err) => {
        logger.error('Failed to authorize Slack:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Slack',
          duration: null,
          description,
        });
      });
  };

  disconnect = (authorization: SlackAuthorization) => {
    const authorizationId = authorization?.id;

    if (!authorizationId) {
      return null;
    }

    return API.deleteSlackAuthorization(authorizationId)
      .then(() => this.fetchSlackAuthorizations())
      .catch((err) =>
        logger.error('Failed to remove Slack authorization:', err)
      );
  };

  updateAuthorizationSettings = async (
    authorization: SlackAuthorization,
    updates: Partial<SlackAuthorizationSettings> = {}
  ) => {
    if (!authorization || !authorization.id) {
      return null;
    }

    const {id: authorizationId, settings = {}} = authorization;

    await API.updateSlackAuthorizationSettings(authorizationId, {
      ...settings,
      ...updates,
    });

    return this.fetchSlackAuthorizations();
  };

  isOnStarterPlan = () => {
    const {account} = this.state;

    if (!account) {
      return false;
    }

    return account.subscription_plan === 'starter';
  };

  render() {
    const {inbox_id: inboxId} = this.props.match.params;
    const {
      authorizations = [],
      selectedSlackAuthorization,
      inbox,
      status,
    } = this.state;

    if (status === 'loading') {
      return null;
    }

    const authorizationUrl = getSlackAuthUrl('support', inboxId);

    return (
      <Container sx={{maxWidth: 720}}>
        <Box mb={4}>
          {inboxId ? (
            <Link to={`/inboxes/${inboxId}`}>
              <Button icon={<ArrowLeftOutlined />}>
                Back to {inbox?.name || 'inbox'}
              </Button>
            </Link>
          ) : (
            <Link to="/integrations">
              <Button icon={<ArrowLeftOutlined />}>Back to integrations</Button>
            </Link>
          )}
        </Box>

        {this.isOnStarterPlan() && (
          <Box mb={4}>
            <Alert
              message={
                <Text>
                  This integration is only available on the Lite and Team
                  subscription plans.{' '}
                  <Link to="billing">Sign up for a free trial!</Link>
                </Text>
              }
              type="warning"
              showIcon
            />
          </Box>
        )}

        <Box mb={4}>
          <Title level={3}>Sync with Slack</Title>

          <Paragraph>
            <Text>Sync messages from your Slack channels with Papercups.</Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/slack.svg" alt="Slack" style={{height: 20}} />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              When you link Papercups with shared Slack channels or public
              support channels, you can sync message threads directly to
              Papercups so you can track and manage feedback from your users
              more easily.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          {authorizations.length > 0 ? (
            authorizations.map((authorization) => {
              const {id, team_name: teamName} = authorization;
              const isSelected = selectedSlackAuthorization?.id === id;

              return (
                <Card sx={{p: 3, mb: 2}} shadow={isSelected ? 'small' : false}>
                  <Flex sx={{justifyContent: 'space-between'}}>
                    <Flex sx={{alignItems: 'center'}}>
                      <img src="/slack.svg" alt="Slack" style={{height: 20}} />
                      <Text strong style={{marginLeft: 8, marginRight: 8}}>
                        {teamName}
                      </Text>
                      {authorization.id && (
                        <Tag icon={<CheckCircleOutlined />} color="success">
                          connected
                        </Tag>
                      )}
                    </Flex>

                    {authorization.id ? (
                      <Flex mx={-1}>
                        {authorizations.length > 1 && (
                          <Box mx={1}>
                            <Button
                              disabled={isSelected}
                              onClick={() =>
                                this.setState({
                                  selectedSlackAuthorization: authorization,
                                })
                              }
                            >
                              {isSelected ? 'Viewing...' : 'Configure'}
                            </Button>
                          </Box>
                        )}

                        <Box mx={1}>
                          <Popconfirm
                            title="Are you sure you want to disconnect this Slack workspace?"
                            okText="Yes"
                            cancelText="No"
                            placement="topLeft"
                            onConfirm={() => this.disconnect(authorization)}
                          >
                            <Button type="primary" danger>
                              Disconnect
                            </Button>
                          </Popconfirm>
                        </Box>
                      </Flex>
                    ) : (
                      <a href={authorizationUrl}>
                        <Button type="primary">Connect</Button>
                      </a>
                    )}
                  </Flex>
                </Card>
              );
            })
          ) : (
            <Card sx={{p: 3, mb: 2}}>
              <Flex sx={{justifyContent: 'space-between'}}>
                <Flex sx={{alignItems: 'center'}}>
                  <img src="/slack.svg" alt="Slack" style={{height: 20}} />
                  <Text strong style={{marginLeft: 8, marginRight: 8}}>
                    Sync with Slack
                  </Text>
                </Flex>

                <a href={authorizationUrl}>
                  <Button type="primary">Connect</Button>
                </a>
              </Flex>
            </Card>
          )}

          {authorizations.length > 0 && (
            <Flex py={2} sx={{justifyContent: 'flex-end'}}>
              <a href={authorizationUrl}>
                <Button size="small" icon={<PlusOutlined />}>
                  Add workspace
                </Button>
              </a>
            </Flex>
          )}
        </Box>

        <IntegrationDetails
          authorization={selectedSlackAuthorization}
          onUpdateSettings={this.updateAuthorizationSettings}
        />
      </Container>
    );
  }
}

export default SlackSyncIntegrationDetails;
