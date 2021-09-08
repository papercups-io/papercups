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
import GithubAuthorizationButton from './GithubAuthorizationButton';
import Spinner from '../Spinner';
import {Account} from '../../types';

type Props = RouteComponentProps<{}>;
type State = {
  status: 'loading' | 'success' | 'error';
  account: Account | null;
  authorization: any | null;
  error: any;
};

class GithubIntegrationDetails extends React.Component<Props, State> {
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
      const {code, installation_id, setup_action} = q;

      if (code || installation_id) {
        // `code` is used for OAuth flow, while `installation_id` is used for app install flow
        const params = code
          ? {code: code ? String(code) : null}
          : {
              installation_id: installation_id ? String(installation_id) : null,
              setup_action: setup_action ? String(setup_action) : null,
            };

        await this.authorize(params);

        history.push(`/integrations/github`);
      }

      this.fetchGithubAuthorization();
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error});
    }
  }

  fetchGithubAuthorization = async () => {
    try {
      const account = await API.fetchAccountInfo();
      const auth = await API.fetchGithubAuthorization();

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

  authorize = async (params: {
    code?: string | null;
    installation_id?: string | null;
    setup_action?: string | null;
  }) => {
    const {code, installation_id} = params;

    if (!code && !installation_id) {
      return null;
    }

    return API.authorizeGithubIntegration(params)
      .then((result) => logger.debug('Successfully authorized Github:', result))
      .catch((err) => {
        logger.error('Failed to authorize Github:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Github',
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

    return API.deleteGithubAuthorization(authorizationId)
      .then(() => this.fetchGithubAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Github authorization:', err)
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
          <Title level={3}>GitHub</Title>

          <Paragraph>
            <Text>Sync and track feature requests and bugs with GitHub.</Text>
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Paragraph>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/github.svg" alt="GitHub" style={{height: 20}} />
                <Text strong style={{marginLeft: 8}}>
                  How does it work?
                </Text>
              </Flex>
            </Paragraph>

            <Text type="secondary">
              When you link Papercups with GitHub, Papercups will automatically
              detect links to GitHub issues and pull requests, and link the
              issue to the person you're chatting with. Then, once the issue is
              resolved, it will send a private notification letting you know
              when the issue is resolved or reopened.
            </Text>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{justifyContent: 'space-between'}}>
              <Flex sx={{alignItems: 'center'}}>
                <img src="/github.svg" alt="GitHub" style={{height: 20}} />
                <Text strong style={{marginLeft: 8, marginRight: 8}}>
                  GitHub
                </Text>
                {hasAuthorization && (
                  <Tag icon={<CheckCircleOutlined />} color="success">
                    connected
                  </Tag>
                )}
              </Flex>

              <GithubAuthorizationButton
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

export default GithubIntegrationDetails;
