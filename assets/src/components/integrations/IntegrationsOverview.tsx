import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';

import {
  notification,
  Alert,
  Container,
  Paragraph,
  Text,
  Title,
} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {IntegrationType, getSlackRedirectUrl} from './support';
import IntegrationsTable from './IntegrationsTable';
import {isEuEdition} from '../../config';
import {Inbox} from '../../types';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  refreshing: boolean;
  inbox: Inbox | null;
  integrations: Array<IntegrationType>;
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    inbox: null,
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
        this.fetchGithubIntegration(),
        // this.fetchGoogleSheetsIntegration(),
        this.fetchHubSpotIntegration(),
        this.fetchSalesforceIntegration(),
        this.fetchZendeskIntegration(),
        this.fetchJiraIntegration(),
      ]);

      this.setState({
        loading: false,
        inbox: await API.fetchPrimaryInbox(),
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
        this.fetchGithubIntegration(),
        // this.fetchGoogleSheetsIntegration(),
        this.fetchHubSpotIntegration(),
        this.fetchSalesforceIntegration(),
        this.fetchZendeskIntegration(),
        this.fetchJiraIntegration(),
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

  fetchGithubIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGithubAuthorization();

    return {
      key: 'github',
      integration: 'GitHub',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/github.svg',
      description: 'Sync and track feature requests and bugs with GitHub.',
    };
  };

  fetchGoogleSheetsIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGoogleAuthorization({client: 'sheets'});

    return {
      key: 'sheets',
      integration: 'Google Sheets (alpha)',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/sheets.svg',
      description: 'Sync customer data to a Google spreadsheet.',
    };
  };

  fetchHubSpotIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'hubspot',
      integration: 'HubSpot',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
      icon: '/hubspot.svg',
    };
  };

  fetchSalesforceIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'salesforce',
      integration: 'Salesforce',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
      icon: '/salesforce.svg',
    };
  };

  fetchJiraIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'jira',
      integration: 'Jira',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
      icon: '/jira.svg',
    };
  };

  fetchZendeskIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'zendesk',
      integration: 'Zendesk',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
      icon: '/zendesk.svg',
    };
  };

  fetchMicrosoftTeamsIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'microsoft-teams',
      integration: 'Microsoft Teams',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
      icon: '/microsoft-teams.svg',
    };
  };

  fetchWhatsAppIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'whatsapp',
      integration: 'WhatsApp',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
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
    const {loading, refreshing, inbox, integrations = []} = this.state;

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
      <Container sx={{maxWidth: 960}}>
        <Box mb={5}>
          <Box mb={4}>
            <Alert
              message={
                <Text>
                  Most integration channels are now handled at the inbox level.{' '}
                  <Link
                    to={inbox && inbox.id ? `/inboxes/${inbox.id}` : '/inboxes'}
                  >
                    Click here
                  </Link>{' '}
                  to configure your inbox integrations.
                </Text>
              }
              type="info"
              showIcon
            />
          </Box>

          <Title level={3}>Integrations</Title>

          <Paragraph>
            <Text>
              Connect with your favorite apps{' '}
              <span role="img" aria-label="apps">
                🚀
              </span>
            </Text>
          </Paragraph>

          <Box my={3}>
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
