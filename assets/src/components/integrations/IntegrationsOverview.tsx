import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';

import {notification, Container, Paragraph, Text, Title} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {IntegrationType, getSlackRedirectUrl} from './support';
import IntegrationsTable from './IntegrationsTable';
import {isEuEdition} from '../../config';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  refreshing: boolean;
  integrations: Array<IntegrationType>;
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    integrations: [],
  };

  async componentDidMount() {
    try {
      const {match, location, history} = this.props;
      const {search} = location;
      const {type} = match.params;

      if (type) {
        await this.handleIntegrationType(type, search);

        history.push('/integrations');
      }

      const integrations = await Promise.all([
        this.fetchSlackIntegration(),
        this.fetchMattermostIntegration(),
        this.fetchGmailIntegration(),
        this.fetchGoogleSheetsIntegration(),
        this.fetchTwilioIntegration(),
        this.fetchGithubIntegration(),
        this.fetchMicrosoftTeamsIntegration(),
        this.fetchWhatsAppIntegration(),
        // TODO: deprecate
        this.fetchSlackSupportIntegration(),
      ]);

      this.setState({
        loading: false,
        integrations: integrations.filter(({key}) =>
          isEuEdition ? !key.startsWith('slack') : true
        ),
      });
    } catch (err) {
      logger.error('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

  refreshAllIntegrations = async () => {
    try {
      this.setState({refreshing: true});

      const integrations = await Promise.all([
        this.fetchSlackIntegration(),
        this.fetchMattermostIntegration(),
        this.fetchGmailIntegration(),
        this.fetchGoogleSheetsIntegration(),
        this.fetchTwilioIntegration(),
        this.fetchGithubIntegration(),
        this.fetchMicrosoftTeamsIntegration(),
        this.fetchWhatsAppIntegration(),
        // TODO: deprecate
        this.fetchSlackSupportIntegration(),
      ]);

      this.setState({
        integrations: integrations.filter(({key}) =>
          isEuEdition ? !key.startsWith('slack') : true
        ),
        refreshing: false,
      });
    } catch (err) {
      logger.error('Error refreshing integrations:', err);

      this.setState({refreshing: false});
    }
  };

  fetchSlackIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchSlackAuthorization('reply');
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Reply to messages from your customers directly through Slack.';

    return {
      key: 'slack',
      integration: 'Reply from Slack',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/slack.svg',
      description,
    };
  };

  fetchMattermostIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchMattermostAuthorization();
    const isConnected =
      auth && auth.channel && auth.access_token && auth.verification_token;
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Reply to messages from your customers directly from Mattermost.';

    return {
      key: 'mattermost',
      integration: 'Reply from Mattermost',
      status: isConnected ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/mattermost.svg',
      description,
    };
  };

  fetchSlackSupportIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchSlackAuthorization('support');
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Sync messages from your Slack channels with Papercups.';

    return {
      key: 'slack:sync',
      integration: 'Sync with Slack (beta)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/slack.svg',
      description,
    };
  };

  fetchGmailIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGoogleAuthorization({
      client: 'gmail',
      type: 'support',
    });

    return {
      key: 'gmail',
      integration: 'Gmail (beta)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/gmail.svg',
      description: 'Sync messages from your Gmail inbox with Papercups.',
    };
  };

  fetchGoogleSheetsIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGoogleAuthorization({client: 'sheets'});

    return {
      key: 'sheets',
      integration: 'Google Sheets (alpha)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/sheets.svg',
      description: 'Sync customer data to a Google spreadsheet.',
    };
  };

  fetchMicrosoftTeamsIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'microsoft-teams',
      integration: 'Microsoft Teams',
      status: 'not_connected',
      created_at: null,
      authorization_id: null,
      icon: '/microsoft-teams.svg',
    };
  };

  fetchTwilioIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchTwilioAuthorization();

    return {
      key: 'twilio',
      integration: 'Twilio',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/twilio.svg',
      description: 'Receive and reply to messages over SMS.',
    };
  };

  fetchGithubIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGithubAuthorization();

    return {
      key: 'github',
      integration: 'GitHub',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/github.svg',
      description: 'Sync and track feature requests and bugs with GitHub.',
    };
  };

  fetchWhatsAppIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'whatsapp',
      integration: 'WhatsApp',
      status: 'not_connected',
      created_at: null,
      authorization_id: null,
      icon: '/whatsapp.svg',
    };
  };

  handleIntegrationType = async (type: string, query: string = '') => {
    switch (type) {
      case 'slack':
        return this.authorizeSlackIntegration(query);
      case 'google':
        return this.authorizeGoogleIntegration(query);
      case 'github':
        return this.authorizeGithubIntegration(query);
      default:
        return null;
    }
  };

  authorizeSlackIntegration = async (query = '') => {
    const q = qs.parse(query);
    const code = q.code ? String(q.code) : null;
    const state = q.state ? String(q.state) : null;

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

  authorizeGoogleIntegration = async (query = '') => {
    const q = qs.parse(query);
    const code = q.code ? String(q.code) : null;

    if (!code) {
      return null;
    }

    const scope = q.scope ? String(q.scope) : null;
    const state = q.state ? String(q.state) : null;

    return API.authorizeGoogleIntegration({code, scope, state})
      .then((result) => logger.debug('Successfully authorized Google:', result))
      .catch((err) => {
        logger.error('Failed to authorize Google:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Google',
          duration: null,
          description,
        });
      });
  };

  authorizeGithubIntegration = async (query = '') => {
    const q = qs.parse(query);
    const {code, installation_id, setup_action} = q;

    if (!code && !installation_id) {
      return null;
    }

    // `code` is used for OAuth flow, while `installation_id` is used for app install flow
    const params = code ? {code} : {installation_id, setup_action};

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

  render() {
    const {loading, refreshing, integrations = []} = this.state;

    if (loading) {
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

    return (
      <Container>
        <Box mb={5}>
          <Title level={3}>Integrations</Title>

          <Paragraph>
            <Text>
              Connect with your favorite apps{' '}
              <span role="img" aria-label="apps">
                🚀
              </span>
            </Text>
          </Paragraph>

          <Box mt={3} mb={4}>
            <IntegrationsTable
              loading={refreshing}
              integrations={integrations}
            />
          </Box>
        </Box>
      </Container>
    );
  }
}

export default IntegrationsOverview;
