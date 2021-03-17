import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {notification, Button, Paragraph, Text, Title} from '../common';
import {PlusOutlined} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {EventSubscription, PersonalApiKey} from '../../types';
import {IntegrationType} from './support';
import IntegrationsTable from './IntegrationsTable';
import WebhooksTable from './WebhooksTable';
import NewWebhookModal from './NewWebhookModal';
import PersonalApiKeysTable from './PersonalApiKeysTable';
import NewApiKeyModal from './NewApiKeyModal';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  refreshing: boolean;
  isWebhookModalOpen: boolean;
  isApiKeyModalOpen: boolean;
  selectedWebhook: EventSubscription | null;
  integrations: Array<IntegrationType>;
  webhooks: Array<EventSubscription>;
  personalApiKeys: Array<PersonalApiKey>;
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    isWebhookModalOpen: false,
    isApiKeyModalOpen: false,
    selectedWebhook: null,
    integrations: [],
    webhooks: [],
    personalApiKeys: [],
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
        this.fetchMicrosoftTeamsIntegration(),
        this.fetchWhatsAppIntegration(),
        // TODO: deprecate
        this.fetchSlackSupportIntegration(),
      ]);
      const webhooks = await API.fetchEventSubscriptions();
      const personalApiKeys = await API.fetchPersonalApiKeys();

      this.setState({integrations, webhooks, personalApiKeys, loading: false});
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
        this.fetchMicrosoftTeamsIntegration(),
        this.fetchWhatsAppIntegration(),
        // TODO: deprecate
        this.fetchSlackSupportIntegration(),
      ]);

      this.setState({integrations, refreshing: false});
    } catch (err) {
      logger.error('Error refreshing integrations:', err);

      this.setState({refreshing: false});
    }
  };

  fetchSlackIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchSlackAuthorization('reply');

    return {
      key: 'slack',
      integration: 'Reply from Slack',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/slack.svg',
      description:
        'Reply to messages from your customers directly through Slack.',
    };
  };

  fetchMattermostIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchMattermostAuthorization();

    return {
      key: 'mattermost',
      integration: 'Reply from Mattermost',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/mattermost.svg',
      description:
        'Reply to messages from your customers directly from Mattermost.',
    };
  };

  fetchSlackSupportIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchSlackAuthorization('support');

    return {
      key: 'slack:sync',
      integration: 'Sync with Slack (beta)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/slack.svg',
      description: 'Sync messages from your Slack channels with Papercups.',
    };
  };

  fetchGmailIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGoogleAuthorization('gmail');

    return {
      key: 'gmail',
      integration: 'Gmail (alpha)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/gmail.svg',
    };
  };

  fetchGoogleSheetsIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchGoogleAuthorization('sheets');

    return {
      key: 'sheets',
      integration: 'Google Sheets (alpha)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/sheets.svg',
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
    return {
      key: 'twilio',
      integration: 'Twilio',
      status: 'not_connected',
      created_at: null,
      authorization_id: null,
      icon: '/twilio.svg',
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
    const q = qs.parse(query);
    const code = q.code ? String(q.code) : null;
    const state = q.state ? String(q.state) : null;

    if (!code) {
      return null;
    }

    switch (type) {
      case 'slack':
        const authorizationType = state || 'reply';

        return API.authorizeSlackIntegration(code, authorizationType)
          .then((result) =>
            logger.debug('Successfully authorized Slack:', result)
          )
          .catch((err) => {
            logger.error('Failed to authorize Slack:', err);

            const description =
              err?.response?.body?.error?.message ||
              err?.message ||
              String(err);

            notification.error({
              message: 'Failed to authorize Slack',
              duration: null,
              description,
            });
          });

      case 'google':
        const scope = q.scope ? String(q.scope) : null;

        return API.authorizeGoogleIntegration(code, scope)
          .then((result) =>
            logger.debug('Successfully authorized Google:', result)
          )
          .catch((err) => logger.error('Failed to authorize Google:', err));
      default:
        return null;
    }
  };

  handleDisconnectSlack = async (authorizationId: string) => {
    return API.deleteSlackAuthorization(authorizationId)
      .then(() => this.refreshAllIntegrations())
      .catch((err) =>
        logger.error('Failed to remove Slack authorization:', err)
      );
  };

  handleAddWebhook = () => {
    this.setState({isWebhookModalOpen: true});
  };

  handleAddApiKey = () => {
    this.setState({isApiKeyModalOpen: true});
  };

  handleUpdateWebhook = (webhook: EventSubscription) => {
    this.setState({isWebhookModalOpen: true, selectedWebhook: webhook});
  };

  handleDeleteWebhook = async (webhook: EventSubscription) => {
    const {id: webhookId} = webhook;

    if (!webhookId) {
      return;
    }

    await API.deleteEventSubscription(webhookId);
    await this.refreshEventSubscriptions();
  };

  handleDeleteApiKey = async (personalApiKey: PersonalApiKey) => {
    const {id: apiKeyId} = personalApiKey;

    if (!apiKeyId) {
      return;
    }

    await API.deletePersonalApiKey(apiKeyId);
    await this.refreshPersonalApiKeys();
  };

  refreshEventSubscriptions = async () => {
    try {
      const webhooks = await API.fetchEventSubscriptions();

      this.setState({webhooks});
    } catch (err) {
      logger.error('Error refreshing event subscriptions:', err);
    }
  };

  refreshPersonalApiKeys = async () => {
    try {
      const personalApiKeys = await API.fetchPersonalApiKeys();

      this.setState({personalApiKeys});
    } catch (err) {
      logger.error('Error refreshing personal API keys:', err);
    }
  };

  handleWebhookModalSuccess = (webhook: EventSubscription) => {
    this.setState({
      isWebhookModalOpen: false,
      selectedWebhook: null,
    });

    this.refreshEventSubscriptions();
  };

  handleWebhookModalCancel = () => {
    this.setState({isWebhookModalOpen: false, selectedWebhook: null});
  };

  handleApiKeyModalSuccess = (personalApiKey: any) => {
    this.setState({isApiKeyModalOpen: false});
    this.refreshPersonalApiKeys();
  };

  handleApiKeyModalCancel = () => {
    this.setState({isApiKeyModalOpen: false});
  };

  render() {
    const {
      loading,
      refreshing,
      isWebhookModalOpen,
      isApiKeyModalOpen,
      selectedWebhook,
      webhooks = [],
      integrations = [],
      personalApiKeys = [],
    } = this.state;

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
      <Box p={4} sx={{maxWidth: 1080}}>
        <Box mb={5}>
          <Title level={4}>Integrations</Title>

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
              onDisconnectSlack={this.handleDisconnectSlack}
              onUpdateIntegration={this.refreshAllIntegrations}
            />
          </Box>
        </Box>

        <Box mb={5}>
          <Title level={4}>Event Subscriptions</Title>

          <Flex sx={{justifyContent: 'space-between', alignItems: 'baseline'}}>
            <Paragraph>
              <Text>
                Create your own integrations with custom webhooks{' '}
                <span role="img" aria-label=":)">
                  🤓
                </span>
              </Text>
            </Paragraph>

            <Button icon={<PlusOutlined />} onClick={this.handleAddWebhook}>
              Add webhook URL
            </Button>
          </Flex>

          <Box my={4}>
            <WebhooksTable
              webhooks={webhooks}
              onUpdateWebhook={this.handleUpdateWebhook}
              onDeleteWebhook={this.handleDeleteWebhook}
            />
          </Box>
        </Box>

        <NewWebhookModal
          webhook={selectedWebhook}
          visible={isWebhookModalOpen}
          onSuccess={this.handleWebhookModalSuccess}
          onCancel={this.handleWebhookModalCancel}
        />

        <Box mb={5}>
          <Title level={4}>Personal API keys</Title>

          <Flex sx={{justifyContent: 'space-between', alignItems: 'baseline'}}>
            <Paragraph>
              <Text>
                Generate personal API keys to interact directly with the
                Papercups API.
              </Text>
            </Paragraph>

            <Button icon={<PlusOutlined />} onClick={this.handleAddApiKey}>
              Generate new API key
            </Button>
          </Flex>

          <Box my={4}>
            <PersonalApiKeysTable
              personalApiKeys={personalApiKeys}
              onDeleteApiKey={this.handleDeleteApiKey}
            />
          </Box>
        </Box>

        <NewApiKeyModal
          visible={isApiKeyModalOpen}
          onSuccess={this.handleApiKeyModalSuccess}
          onCancel={this.handleApiKeyModalCancel}
        />
      </Box>
    );
  }
}

export default IntegrationsOverview;
