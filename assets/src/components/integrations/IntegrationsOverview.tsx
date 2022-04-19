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
  Card,
} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {IntegrationType, getSlackRedirectUrl} from './support';
import IntegrationsTable from './IntegrationsTable';
import {isEuEdition} from '../../config';
import {Inbox} from '../../types';
import {InboxIntegrationsTable} from '../inboxes/InboxIntegrations';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  refreshing: boolean;
  inbox: Inbox | null;
  integrations: Array<IntegrationType>;
  integrationsByKey: {[key: string]: IntegrationType};
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    inbox: null,
    integrations: [],
    integrationsByKey: {},
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

      const inboxes = await API.fetchInboxes();
      const [first] = inboxes;
      const primary = inboxes.find((inbox) => inbox.is_primary);
      const inbox = primary || first;
      const integrations = await Promise.all([
        this.fetchChatIntegration(inbox),
        this.fetchSlackIntegration(inbox),
        this.fetchEmailForwardingIntegration(inbox),
        this.fetchMattermostIntegration(inbox),
        this.fetchGmailIntegration(inbox),
        this.fetchTwilioIntegration(inbox),
        this.fetchSlackSupportIntegration(inbox),
        // Account level only
        this.fetchGithubIntegration(),
        this.fetchHubSpotIntegration(),
        this.fetchIntercomIntegration(),
        this.fetchSalesforceIntegration(),
        this.fetchZendeskIntegration(),
        this.fetchJiraIntegration(),
        this.fetchGoogleSheetsIntegration(),
      ]);

      this.setState({
        loading: false,
        inbox: inbox,
        integrations: integrations.filter(({key}) =>
          isEuEdition ? !key.startsWith('slack') : true
        ),
        integrationsByKey: integrations.reduce((acc, integration) => {
          return {...acc, [integration.key]: integration};
        }, {}),
      });
    } catch (err) {
      logger.error('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

  fetchChatIntegration = async (inbox: Inbox): Promise<IntegrationType> => {
    const {id: inboxId, account_id: accountId} = inbox;
    const widgetSettings = await API.fetchWidgetSettings({
      account_id: accountId,
      inbox_id: inboxId,
    });
    const {count = 0} = await API.countAllConversations({inbox_id: inboxId});
    const {id: widgetSettingsId, created_at: createdAt} = widgetSettings;
    const description = 'Chat with users on your website via Papercups.';
    const isConnected = count > 0;

    return {
      key: 'chat',
      integration: 'Live chat',
      status: isConnected ? 'connected' : 'not_connected',
      createdAt: isConnected ? createdAt : null,
      icon: '/logo.svg',
      isPopular: true,
      description,
      configurationUrl: `/inboxes/${inboxId}/chat-widget`,
      // TODO: deprecate?
      authorizationId: widgetSettingsId || null,
    };
  };

  fetchSlackIntegration = async (inbox: Inbox): Promise<IntegrationType> => {
    const {id: inboxId} = inbox;
    const auth = await API.fetchSlackAuthorization('reply', {
      inbox_id: inboxId,
    });
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Reply to messages from your customers directly through Slack.';

    return {
      key: 'slack',
      integration: 'Reply from Slack',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/slack.svg',
      isPopular: true,
      description,
      configurationUrl: `/inboxes/${inboxId}/integrations/slack/reply`,
    };
  };

  fetchMattermostIntegration = async (
    inbox: Inbox
  ): Promise<IntegrationType> => {
    const {id: inboxId} = inbox;
    const auth = await API.fetchMattermostAuthorization({inbox_id: inboxId});
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
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/mattermost.svg',
      description,
      configurationUrl: `/inboxes/${inboxId}/integrations/mattermost`,
    };
  };

  fetchSlackSupportIntegration = async (
    inbox: Inbox
  ): Promise<IntegrationType> => {
    const {id: inboxId} = inbox;
    const auth = await API.fetchSlackAuthorization('support', {
      inbox_id: inboxId,
    });
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Sync messages from your Slack channels with Papercups.';

    return {
      key: 'slack:sync',
      integration: 'Sync with Slack (beta)',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/slack.svg',
      description,
      configurationUrl: `/inboxes/${inboxId}/integrations/slack/support`,
    };
  };

  fetchGmailIntegration = async (inbox: Inbox): Promise<IntegrationType> => {
    const {id: inboxId} = inbox;
    const auth = await API.fetchGoogleAuthorization({
      client: 'gmail',
      type: 'support',
      inbox_id: inboxId,
    });

    return {
      key: 'gmail',
      integration: 'Gmail (beta)',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/gmail.svg',
      description: 'Sync messages from your Gmail inbox with Papercups.',
      configurationUrl: `/inboxes/${inboxId}/integrations/google/gmail`,
    };
  };

  fetchEmailForwardingIntegration = async (
    inbox: Inbox
  ): Promise<IntegrationType> => {
    const {id: inboxId} = inbox;
    const addresses = await API.fetchForwardingAddresses({inbox_id: inboxId});
    const [first] = addresses;

    return {
      key: 'ses',
      integration: 'Email forwarding',
      status: first ? 'connected' : 'not_connected',
      createdAt: first ? first.created_at : null,
      authorizationId: first ? first.id : null,
      icon: '/ses.svg',
      isPopular: true,
      description: 'Set up email forwarding into Papercups.',
      configurationUrl: `/inboxes/${inboxId}/email-forwarding`,
    };
  };

  fetchTwilioIntegration = async (inbox: Inbox): Promise<IntegrationType> => {
    const {id: inboxId} = inbox;
    const auth = await API.fetchTwilioAuthorization({inbox_id: inboxId});

    return {
      key: 'twilio',
      integration: 'Twilio',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/twilio.svg',
      description: 'Receive and reply to messages over SMS.',
      configurationUrl: `/inboxes/${inboxId}/integrations/twilio`,
    };
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
    const auth = await API.fetchHubspotAuthorization();

    return {
      key: 'hubspot',
      integration: 'HubSpot',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/hubspot.svg',
      description: 'View and sync customer data from HubSpot',
    };
  };

  fetchIntercomIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchIntercomAuthorization();

    return {
      key: 'intercom',
      integration: 'Intercom',
      status: auth ? 'connected' : 'not_connected',
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/intercom.svg',
      description: 'View and sync customer data from Intercom',
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

  getIntegrationsByKeys = (keys: Array<string>) => {
    const {integrationsByKey = {}} = this.state;

    return keys.map((key) => integrationsByKey[key] || null).filter(Boolean);
  };

  getPopularIntegrations = () => {
    const {integrationsByKey = {}} = this.state;

    return Object.keys(integrationsByKey)
      .map((key) => integrationsByKey[key])
      .filter((record) => {
        return record && record.isPopular;
      });
  };

  getInboxSourceChannels = () => {
    return this.getIntegrationsByKeys([
      'chat',
      'ses',
      'gmail',
      'twilio',
      'slack:sync',
    ]);
  };

  getInboxReplyChannels = () => {
    return this.getIntegrationsByKeys(['slack', 'mattermost']);
  };

  getAccountLevelIntegrations = () => {
    return this.getIntegrationsByKeys([
      'github',
      'sheets',
      'hubspot',
      'intercom',
      'salesforce',
      'zendesk',
      'jira',
    ]);
  };

  render() {
    const {loading, refreshing, inbox} = this.state;

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
          <Title level={3}>Integrations</Title>

          <Paragraph>
            <Text>
              Connect Papercups with your favorite apps{' '}
              <span role="img" aria-label="apps">
                🚀
              </span>
            </Text>
          </Paragraph>

          {inbox && inbox.id && (
            <Box my={4}>
              <Card sx={{p: 3}}>
                <Box mb={4}>
                  <Alert
                    message={
                      <Text>
                        Most integration channels are now handled at the inbox
                        level. <Link to="/inboxes">Click here</Link> to
                        configure your inboxes.
                      </Text>
                    }
                    type="info"
                    showIcon
                  />
                </Box>

                <Box px={3} mb={3}>
                  <Title level={4}>Popular</Title>
                </Box>
                <Box mb={4}>
                  <InboxIntegrationsTable
                    loading={refreshing}
                    inboxId={inbox.id}
                    integrations={this.getPopularIntegrations()}
                  />
                </Box>

                <Box px={3} mb={3}>
                  <Title level={4}>Inbox source channels</Title>
                </Box>
                <Box mb={4}>
                  <InboxIntegrationsTable
                    loading={refreshing}
                    inboxId={inbox.id}
                    integrations={this.getInboxSourceChannels()}
                  />
                </Box>

                <Box px={3} mb={3}>
                  <Title level={4}>Inbox reply channels</Title>
                </Box>
                <Box mb={4}>
                  <InboxIntegrationsTable
                    loading={refreshing}
                    inboxId={inbox.id}
                    integrations={this.getInboxReplyChannels()}
                  />
                </Box>
              </Card>
            </Box>
          )}

          <Box my={4}>
            <Card sx={{p: 3}}>
              <Box px={3} mb={3}>
                <Title level={4}>Account-level integrations</Title>
              </Box>
              <Box mb={4}>
                <IntegrationsTable
                  loading={refreshing}
                  integrations={this.getAccountLevelIntegrations()}
                />
              </Box>
            </Card>
          </Box>
        </Box>
      </Container>
    );
  }
}

export default IntegrationsOverview;
