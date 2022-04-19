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
import {TwilioAuthorizationButton} from './TwilioAuthorizationModal';
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

class TwilioIntegrationDetails extends React.Component<Props, State> {
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

      this.fetchTwilioAuthorization();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchTwilioAuthorization = async () => {
    try {
      const {inbox_id: inboxId} = this.props.match.params;
      const account = await API.fetchAccountInfo();
      const auth = await API.fetchTwilioAuthorization({inbox_id: inboxId});

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

    return API.deleteTwilioAuthorization(authorizationId)
      .then(() => this.fetchTwilioAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Twilio authorization:', err)
      );
  };

  hasValidAuthorization = () => {
    const {authorization} = this.state;

    if (!authorization) {
      return false;
    }

    const {
      id,
      from_phone_number: phoneNumber,
      twilio_account_sid: accountSid,
      twilio_auth_token: authToken,
    } = authorization;

    return !!(id && phoneNumber && accountSid && authToken);
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
          <Title level={3}>Twilio</Title>

          <Paragraph>
            <Text>Receive and reply to messages over SMS.</Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/twilio.svg" alt="Twilio" style={{height: 20}} />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              When you link Papercups with Twilio, your customers can message
              you via SMS and you can reply directly via Papercups.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/twilio.svg" alt="Twilio" style={{height: 20}} />
                <Text strong style={{marginLeft: 8, marginRight: 8}}>
                  Twilio
                </Text>
                {this.hasValidAuthorization() && (
                  <Tag icon={<CheckCircleOutlined />} color="success">
                    connected
                  </Tag>
                )}
              </Flex>

              <TwilioAuthorizationButton
                authorizationId={authorization?.id}
                inboxId={inboxId}
                isConnected={hasAuthorization}
                onUpdate={this.fetchTwilioAuthorization}
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
              <label>Phone number</label>
              <Box>
                {authorization && authorization.from_phone_number ? (
                  <Text strong>{authorization.from_phone_number}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>
            <Box mb={3}>
              <label>Account SID</label>
              <Box>
                {authorization && authorization.twilio_account_sid ? (
                  <Text strong>{authorization.twilio_account_sid}</Text>
                ) : (
                  <Text type="secondary">Not connected</Text>
                )}
              </Box>
            </Box>

            <Box mb={3}>
              <label>Auth token</label>
              <Box>
                {authorization && authorization.twilio_auth_token ? (
                  <Text>●●●●●●●●●●●●●●●●</Text>
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

export default TwilioIntegrationDetails;
