import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Twemoji} from 'react-emoji-render';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {
  notification,
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
import {SlackAuthorization, SlackAuthorizationSettings} from '../../types';
import {getSlackAuthUrl, getSlackRedirectUrl} from './support';
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

type Props = RouteComponentProps<{}>;
type State = {
  status: 'loading' | 'success' | 'error';
  authorizations: Array<SlackAuthorization>;
  selectedSlackAuthorization: SlackAuthorization | null;
  error: any;
};

class SlackSyncIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    authorizations: [],
    selectedSlackAuthorization: null,
    error: null,
  };

  async componentDidMount() {
    try {
      const {location, history} = this.props;
      const {search} = location;
      const q = qs.parse(search);
      const code = q.code ? String(q.code) : null;

      if (code) {
        await this.authorize(code, q);

        history.push(`/integrations/slack/support`);
      }

      this.fetchSlackAuthorizations();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchSlackAuthorizations = async () => {
    try {
      const authorizations = await API.listSlackAuthorizations('support');
      const [selected = null] = authorizations;

      this.setState({
        authorizations,
        selectedSlackAuthorization:
          this.state.selectedSlackAuthorization || selected,
        status: 'success',
      });
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  };

  authorize = async (code: string, query: any) => {
    const state = query.state ? String(query.state) : null;

    if (!code) {
      return null;
    }

    const authorizationType = state || 'reply';

    return API.authorizeSlackIntegration({
      code,
      type: authorizationType,
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
    // const {authorization} = this.state;
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

  render() {
    const {
      authorizations = [],
      selectedSlackAuthorization,
      status,
    } = this.state;

    if (status === 'loading') {
      return null;
    }

    const settings = selectedSlackAuthorization?.settings;

    return (
      <Container sx={{maxWidth: 720}}>
        <Box mb={4}>
          <Link to="/integrations">
            <Button icon={<ArrowLeftOutlined />}>Back to integrations</Button>
          </Link>
        </Box>

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
          {authorizations.map((authorization) => {
            const {team_name: teamName} = authorization;

            return (
              <Card sx={{p: 3, mb: 2}}>
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
                      <Box mx={1}>
                        {/* TODO: on click, set as selected authorization to view settings below */}
                        <Button
                          onClick={() =>
                            this.setState({
                              selectedSlackAuthorization: authorization,
                            })
                          }
                        >
                          Settings
                        </Button>
                      </Box>
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
                    <a href={getSlackAuthUrl('support')}>
                      <Button type="primary">Connect</Button>
                    </a>
                  )}
                </Flex>
              </Card>
            );
          })}

          <Flex py={2} sx={{justifyContent: 'flex-end'}}>
            <a href={getSlackAuthUrl('support')}>
              <Button size="small" icon={<PlusOutlined />}>
                Add workspace
              </Button>
            </a>
          </Flex>
        </Box>

        <Box mb={4}>
          <Title level={4}>
            {selectedSlackAuthorization
              ? `Settings for ${selectedSlackAuthorization.team_name}`
              : 'Integration settings'}
          </Title>

          <Card
            sx={{
              p: 3,
              bg: 'rgb(245, 245, 245)',
              opacity: selectedSlackAuthorization ? 1 : 0.6,
            }}
          >
            <Box mb={3}>
              <label>Channel</label>
              <Box>
                {selectedSlackAuthorization &&
                selectedSlackAuthorization.channel ? (
                  <Text strong>{selectedSlackAuthorization.channel}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Team</label>
              <Box>
                {selectedSlackAuthorization &&
                selectedSlackAuthorization.team_name ? (
                  <Text strong>{selectedSlackAuthorization.team_name}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Slack configuration URL</label>
              <Box>
                {selectedSlackAuthorization &&
                selectedSlackAuthorization.configuration_url ? (
                  <Text>
                    <a
                      href={selectedSlackAuthorization.configuration_url}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {selectedSlackAuthorization.configuration_url}
                    </a>
                  </Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>

            {selectedSlackAuthorization && settings && (
              <>
                <Divider />

                <IntegrationSettings
                  settings={settings}
                  onUpdateSettings={(updates) =>
                    this.updateAuthorizationSettings(
                      selectedSlackAuthorization,
                      updates
                    )
                  }
                />
              </>
            )}
          </Card>
        </Box>
      </Container>
    );
  }
}

export default SlackSyncIntegrationDetails;
