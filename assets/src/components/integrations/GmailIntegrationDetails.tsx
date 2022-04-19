import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';

import {
  notification,
  Alert,
  Button,
  Card,
  Container,
  Divider,
  Paragraph,
  Tag,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined, CheckCircleOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {SupportGmailAuthorizationButton} from './GoogleAuthorizationButton';
import Spinner from '../Spinner';
import {Account, Inbox} from '../../types';
import {parseGoogleAuthState} from './support';

dayjs.extend(utc);

type Props = RouteComponentProps<{inbox_id?: string}>;
type State = {
  status: 'loading' | 'success' | 'error';
  account: Account | null;
  inbox: Inbox | null;
  authorization: any | null;
  connectedEmailAddress: string | null;
  error: any;
};

class GmailIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    account: null,
    inbox: null,
    authorization: null,
    connectedEmailAddress: null,
    error: null,
  };

  async componentDidMount() {
    try {
      const {location, history, match} = this.props;
      const {search} = location;
      const q = qs.parse(search);
      const code = q.code ? String(q.code) : null;

      if (code) {
        const state = q.state ? String(q.state) : '';
        const scope = q.scope ? String(q.scope) : '';
        const {type, inboxId} = parseGoogleAuthState(state);
        const redirect = inboxId
          ? `/inboxes/${inboxId}/integrations/google/gmail`
          : `/integrations/google/gmail`;

        await this.authorize(code, {
          scope,
          state: type,
          inbox_id: inboxId,
        });

        history.push(redirect);
      }

      const {inbox_id: inboxId} = match.params;

      if (inboxId) {
        const inbox = await API.fetchInbox(inboxId);

        this.setState({inbox});
      }

      this.fetchGoogleAuthorization();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchGoogleAuthorization = async () => {
    try {
      const {inbox_id: inboxId} = this.props.match.params;
      const account = await API.fetchAccountInfo();
      const auth = await API.fetchGoogleAuthorization({
        client: 'gmail',
        type: 'support',
        inbox_id: inboxId,
      });

      if (auth) {
        const profile = await API.fetchGmailProfile({inbox_id: inboxId});

        this.setState({
          account,
          authorization: auth,
          connectedEmailAddress: profile?.email ?? null,
          status: 'success',
        });
      } else {
        this.setState({
          account,
          authorization: null,
          connectedEmailAddress: null,
          status: 'success',
        });
      }
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  };

  authorize = async (
    code: string,
    params: {
      scope: string | null;
      state: string | null;
      inbox_id: string | null;
    }
  ) => {
    const {scope, state, inbox_id} = params;

    if (!code) {
      return null;
    }

    return API.authorizeGoogleIntegration({code, scope, state, inbox_id})
      .then((result) => logger.debug('Successfully authorized Gmail:', result))
      .catch((err) => {
        logger.error('Failed to authorize Gmail:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Gmail',
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

    return API.deleteGoogleAuthorization(authorizationId)
      .then(() => this.fetchGoogleAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Gmail authorization:', err)
      );
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
    const {authorization, inbox, connectedEmailAddress, status} = this.state;

    if (status === 'loading') {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    }

    const hasAuthorization = !!(authorization && authorization.id);

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
          <Title level={3}>Gmail (beta)</Title>

          <Paragraph>
            <Text>Sync messages from your Gmail inbox with Papercups.</Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/gmail.svg" alt="Gmail" style={{height: 20}} />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              When you link Papercups with Gmail, messages that arrive in your
              Gmail inbox will be synced with Papercups. This enables you to
              view and reply to emails directly from the Papercups dashboard, or
              from any of our other integrations (e.g.{' '}
              <Link to="/integrations/slack/reply">Reply from Slack</Link>).
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/gmail.svg" alt="Gmail" style={{height: 20}} />
                <Text strong style={{marginLeft: 8, marginRight: 8}}>
                  Gmail (beta)
                </Text>
                {hasAuthorization && (
                  <Tag icon={<CheckCircleOutlined />} color="success">
                    connected
                  </Tag>
                )}
              </Flex>

              <SupportGmailAuthorizationButton
                isConnected={hasAuthorization}
                inboxId={inboxId}
                authorizationId={authorization?.id}
                onDisconnectGmail={this.disconnect}
              />
            </Flex>
          </Card>
        </Box>

        <Box mb={4}>
          <Title level={4}>Integration settings</Title>

          <Card
            sx={{
              p: 3,
              bg: 'rgb(245, 245, 245)',
              opacity: hasAuthorization ? 1 : 0.6,
            }}
          >
            <Box mb={3}>
              <label>Connected email</label>
              <Box>
                {connectedEmailAddress ? (
                  <Text strong>{connectedEmailAddress}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Last synced</label>
              <Box>
                {authorization && authorization.updated_at ? (
                  <Text strong>
                    {dayjs
                      .utc(authorization.updated_at)
                      .local()
                      .format('MMMM D, h:mm a')}
                  </Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
          </Card>
        </Box>
      </Container>
    );
  }
}

export default GmailIntegrationDetails;
