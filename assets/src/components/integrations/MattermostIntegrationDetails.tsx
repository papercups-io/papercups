import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {
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
import {MattermostAuthorizationButton} from './MattermostAuthorizationModal';
import Spinner from '../Spinner';
import {Account, Inbox} from '../../types';

type Props = RouteComponentProps<{inbox_id?: string}>;
type State = {
  status: 'loading' | 'success' | 'error';
  account: Account | null;
  inbox: Inbox | null;
  authorization: any | null;
  error: any;
};

class MattermostIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    account: null,
    inbox: null,
    authorization: null,
    error: null,
  };

  async componentDidMount() {
    try {
      const {inbox_id: inboxId} = this.props.match.params;

      if (inboxId) {
        const inbox = await API.fetchInbox(inboxId);

        this.setState({inbox});
      }

      this.fetchMattermostAuthorization();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchMattermostAuthorization = async () => {
    try {
      const {inbox_id: inboxId} = this.props.match.params;
      const account = await API.fetchAccountInfo();
      const auth = await API.fetchMattermostAuthorization({inbox_id: inboxId});

      this.setState({
        account,
        authorization: auth,
        status: 'success',
      });
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  };

  disconnect = () => {
    const {authorization} = this.state;
    const authorizationId = authorization?.id;

    if (!authorizationId) {
      return null;
    }

    return API.deleteMattermostAuthorization(authorizationId)
      .then(() => this.fetchMattermostAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Mattermost authorization:', err)
      );
  };

  hasValidAuthorization = () => {
    const {authorization} = this.state;

    if (!authorization) {
      return false;
    }

    const {
      id,
      channel,
      mattermost_url: url,
      access_token: botAccessToken,
      verification_token: verificationToken,
    } = authorization;

    return !!(id && url && channel && botAccessToken && verificationToken);
  };

  render() {
    const {inbox_id: inboxId} = this.props.match.params;
    const {authorization, inbox, status} = this.state;

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

        <Box mb={4}>
          <Title level={3}>Mattermost</Title>

          <Paragraph>
            <Text>
              Reply to messages from your customers directly from Mattermost.
            </Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img
                  src="/mattermost.svg"
                  alt="Mattermost"
                  style={{height: 20}}
                />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              When you link Papercups with Mattermost, all new incoming messages
              will be forwarded to the Mattermost channel of your choosing. From
              the comfort of your team's Mattermost workspace, you can easily
              reply to conversations with your users.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img
                  src="/mattermost.svg"
                  alt="Mattermost"
                  style={{height: 20}}
                />
                <Text strong style={{marginLeft: 8, marginRight: 8}}>
                  Mattermost
                </Text>
                {this.hasValidAuthorization() && (
                  <Tag icon={<CheckCircleOutlined />} color="success">
                    connected
                  </Tag>
                )}
              </Flex>

              <MattermostAuthorizationButton
                authorizationId={authorization?.id}
                inboxId={inboxId}
                isConnected={hasAuthorization}
                onUpdate={this.fetchMattermostAuthorization}
                onDisconnect={this.disconnect}
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
              <label>URL</label>
              <Box>
                {authorization && authorization.mattermost_url ? (
                  <Text strong>{authorization.mattermost_url}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
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
              <label>Bot access token</label>
              <Box>
                {authorization && authorization.access_token ? (
                  <Text>●●●●●●●●●●●●●●●●</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Outgoing webhook token</label>
              <Box>
                {authorization && authorization.verification_token ? (
                  <Text>●●●●●●●●</Text>
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

export default MattermostIntegrationDetails;
