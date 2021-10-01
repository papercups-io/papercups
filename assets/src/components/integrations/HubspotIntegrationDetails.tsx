import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';

import {
  notification,
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
import HubspotAuthorizationButton from './HubspotAuthorizationButton';
import Spinner from '../Spinner';
import {Account} from '../../types';

type Props = RouteComponentProps<{}>;
type State = {
  status: 'loading' | 'success' | 'error';
  account: Account | null;
  authorization: any | null;
  error: any;
};

class HubspotIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    account: null,
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
        await this.authorize(code);

        history.push(`/integrations/hubspot`);
      }

      this.fetchHubspotAuthorization();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchHubspotAuthorization = async () => {
    try {
      const account = await API.fetchAccountInfo();
      const auth = await API.fetchHubspotAuthorization();

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

  authorize = async (code: string | null) => {
    if (!code) {
      return null;
    }

    return API.authorizeHubspotIntegration({code})
      .then((result) =>
        logger.debug('Successfully authorized Hubspot:', result)
      )
      .catch((err) => {
        logger.error('Failed to authorize Hubspot:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Hubspot',
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

    return API.deleteHubspotAuthorization(authorizationId)
      .then(() => this.fetchHubspotAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Hubspot authorization:', err)
      );
  };

  render() {
    const {authorization, status} = this.state;

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
          <Link to="/integrations">
            <Button icon={<ArrowLeftOutlined />}>Back to integrations</Button>
          </Link>
        </Box>

        <Box mb={4}>
          <Title level={3}>HubSpot</Title>

          <Paragraph>
            <Text>Sync and view customer data from HubSpot.</Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/hubspot.svg" alt="HubSpot" style={{height: 20}} />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              When you link Papercups with HubSpot, you can easily view and sync
              data with your customers in HubSpot.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/hubspot.svg" alt="HubSpot" style={{height: 20}} />
                <Text strong style={{marginLeft: 8, marginRight: 8}}>
                  HubSpot
                </Text>
                {hasAuthorization && (
                  <Tag icon={<CheckCircleOutlined />} color="success">
                    connected
                  </Tag>
                )}
              </Flex>

              <HubspotAuthorizationButton
                authorizationId={authorization?.id}
                isConnected={hasAuthorization}
                onDisconnect={this.disconnect}
              />
            </Flex>
          </Card>
        </Box>
      </Container>
    );
  }
}

export default HubspotIntegrationDetails;
