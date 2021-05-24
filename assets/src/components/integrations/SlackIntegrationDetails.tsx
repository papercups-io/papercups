import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {
  notification,
  Button,
  Card,
  Divider,
  Paragraph,
  Popconfirm,
  Text,
  Title,
} from '../common';
import * as API from '../../api';
import {SlackAuthorization} from '../../types';
import {getSlackAuthUrl, getSlackRedirectUrl} from './support';
import logger from '../../logger';

type Props = RouteComponentProps<{}>;
type State = {
  status: 'loading' | 'success' | 'error';
  authorization: SlackAuthorization | null;
  error: any;
};

class SlackIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    authorization: null,
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

        history.push('/integrations/slack');
      }

      this.fetchSlackAuthorization();
    } catch (error) {
      this.setState({status: 'error', error});
    }
  }

  fetchSlackAuthorization = async () => {
    try {
      const auth = await API.fetchSlackAuthorization('reply');

      this.setState({authorization: auth, status: 'success'});
    } catch (error) {
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

  disconnect = () => {
    const {authorization} = this.state;
    const authorizationId = authorization?.id;

    if (!authorizationId) {
      return null;
    }

    return API.deleteSlackAuthorization(authorizationId)
      .then(() => this.fetchSlackAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Slack authorization:', err)
      );
  };

  render() {
    const {authorization, status} = this.state;

    if (status === 'loading') {
      return null;
    }

    return (
      <Box p={4} sx={{maxWidth: 720}}>
        <Box mb={4}>
          <Title level={3}>Reply from Slack</Title>

          <Paragraph>
            <Text>
              Reply to messages from your customers directly through Slack.
            </Text>
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
              When you link Papercups with Slack, all new incoming messages will
              be forwarded to the Slack channel of your choosing. From the
              comfort of your team's Slack workspace, you can reply to and
              resolve conversations with your users.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/slack.svg" alt="Slack" style={{height: 20}} />
                <Text strong style={{marginLeft: 8}}>
                  Reply to messages from Slack
                </Text>
              </Flex>

              {authorization && authorization.id ? (
                <Popconfirm
                  title="Are you sure you want to disconnect from Slack?"
                  okText="Yes"
                  cancelText="No"
                  placement="topLeft"
                  onConfirm={() => this.disconnect()}
                >
                  <Button danger>Disconnect</Button>
                </Popconfirm>
              ) : (
                <a href={getSlackAuthUrl('reply')}>
                  <Button type="primary">Connect</Button>
                </a>
              )}
            </Flex>
          </Card>
        </Box>

        <Box mb={4}>
          <Title level={4}>Integration settings</Title>

          <Card
            sx={{
              p: 3,
              bg: 'rgb(245, 245, 245)',
              opacity: authorization && authorization.id ? 1 : 0.6,
            }}
          >
            <Box mb={3}>
              <label>Channel</label>
              <Box>
                {authorization && authorization.channel ? (
                  <Text strong>{authorization.channel}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Team</label>
              <Box>
                {authorization && authorization.team_name ? (
                  <Text strong>{authorization.team_name}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Slack configuration URL</label>
              <Box>
                {authorization && authorization.configuration_url ? (
                  <Text>
                    <a
                      href={`https://slack.com/app_redirect?channel=${authorization.configuration_url}`}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {authorization.configuration_url}
                    </a>
                  </Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
          </Card>
        </Box>
      </Box>
    );
  }
}

export default SlackIntegrationDetails;
