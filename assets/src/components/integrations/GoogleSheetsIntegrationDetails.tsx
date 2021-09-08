import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';

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
import {GoogleSheetsAuthorizationButton} from './GoogleAuthorizationButton';
import Spinner from '../Spinner';
import {Account} from '../../types';

type Props = RouteComponentProps<{}>;
type State = {
  status: 'loading' | 'success' | 'error';
  account: Account | null;
  authorization: any | null;
  error: any;
};

class GoogleSheetsIntegrationDetails extends React.Component<Props, State> {
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
        await this.authorize(code, q);

        history.push(`/integrations/google/sheets`);
      }

      this.fetchGoogleAuthorization();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchGoogleAuthorization = async () => {
    try {
      const account = await API.fetchAccountInfo();
      const auth = await API.fetchGoogleAuthorization({
        client: 'sheets',
      });

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

  authorize = async (code: string, query: any) => {
    if (!code) {
      return null;
    }

    const scope = query.scope ? String(query.scope) : null;
    const state = query.state ? String(query.state) : null;

    return API.authorizeGoogleIntegration({code, scope, state})
      .then((result) =>
        logger.debug('Successfully authorized Google Sheets:', result)
      )
      .catch((err) => {
        logger.error('Failed to authorize Google Sheets:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Google Sheets',
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
        logger.error('Failed to remove Google Sheets authorization:', err)
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
          <Title level={3}>Google Sheets (alpha)</Title>

          <Paragraph>
            <Text>Sync customer data from and to Google spreadsheets.</Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img
                  src="/sheets.svg"
                  alt="Google Sheets"
                  style={{height: 20}}
                />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              Linking Papercups with Google Sheets will enable you to start
              syncing your customer data to a spreadsheet instantaneously. It
              also will allow you to import customer data much more easily.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img
                  src="/sheets.svg"
                  alt="Google Sheets"
                  style={{height: 20}}
                />
                <Text strong style={{marginLeft: 8, marginRight: 8}}>
                  Google Sheets (alpha)
                </Text>
                {hasAuthorization && (
                  <Tag icon={<CheckCircleOutlined />} color="success">
                    connected
                  </Tag>
                )}
              </Flex>

              <GoogleSheetsAuthorizationButton
                isConnected={hasAuthorization}
                authorizationId={authorization?.id}
                onDisconnect={this.disconnect}
              />
            </Flex>
          </Card>
        </Box>
      </Container>
    );
  }
}

export default GoogleSheetsIntegrationDetails;
