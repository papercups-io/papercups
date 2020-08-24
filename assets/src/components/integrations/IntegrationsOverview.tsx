import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {Button, Paragraph, Text, Title} from '../common';
import {PlusOutlined} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import {IntegrationType, WebhookEventSubscription} from './support';
import IntegrationsTable from './IntegrationsTable';
import WebhooksTable from './WebhooksTable';
import NewWebhookModal from './NewWebhookModal';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  isWebhookModalOpen: boolean;
  selectedWebhook: WebhookEventSubscription | null;
  integrations: Array<IntegrationType>;
  webhooks: Array<WebhookEventSubscription>;
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    isWebhookModalOpen: false,
    selectedWebhook: null,
    integrations: [],
    webhooks: [],
  };

  async componentDidMount() {
    try {
      const {match, location} = this.props;
      const {search} = location;
      const {type} = match.params;

      if (type) {
        await this.handleIntegrationType(type, search);
      }

      const integrations = await Promise.all([
        this.fetchSlackIntegration(),
        this.fetchGmailIntegration(),
      ]);
      const webhooks = await API.fetchEventSubscriptions();

      this.setState({integrations, webhooks, loading: false});
    } catch (err) {
      console.log('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

  fetchSlackIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchSlackAuthorization();

    return {
      key: 'slack',
      integration: 'Slack',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      icon: '/slack.svg',
    };
  };

  fetchGmailIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'gmail',
      integration: 'Gmail',
      status: 'not_connected',
      created_at: null,
      icon: '/gmail.svg',
    };
  };

  handleIntegrationType = (type: string, query: string = '') => {
    const q = qs.parse(query);

    switch (type) {
      case 'slack':
        const code = String(q.code);

        return API.authorizeSlackIntegration(code).catch((err) =>
          console.log('Failed to authorize Slack:', err)
        );
      default:
        return null;
    }
  };

  handleAddWebhook = () => {
    this.setState({isWebhookModalOpen: true});
  };

  handleUpdateWebhook = (webhook: WebhookEventSubscription) => {
    this.setState({isWebhookModalOpen: true, selectedWebhook: webhook});
  };

  handleDeleteWebhook = async (webhook: WebhookEventSubscription) => {
    const {id: webhookId} = webhook;

    if (!webhookId) {
      return;
    }

    await API.deleteEventSubscription(webhookId);
    await this.refreshEventSubscriptions();
  };

  refreshEventSubscriptions = async () => {
    try {
      const webhooks = await API.fetchEventSubscriptions();

      this.setState({webhooks});
    } catch (err) {
      console.log('Error refreshing event subscriptions:', err);
    }
  };

  handleWebhookModalSuccess = (webhook: WebhookEventSubscription) => {
    this.setState({
      isWebhookModalOpen: false,
      selectedWebhook: null,
    });

    this.refreshEventSubscriptions();
  };

  handleWebhookModalCancel = () => {
    this.setState({isWebhookModalOpen: false, selectedWebhook: null});
  };

  render() {
    const {
      loading,
      isWebhookModalOpen,
      selectedWebhook,
      webhooks = [],
      integrations = [],
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
      <Box p={4}>
        <Box mb={4}>
          <Title level={4}>Integrations</Title>

          <Paragraph>
            <Text>
              Connect with your favorite apps{' '}
              <span role="img" aria-label="apps">
                🚀
              </span>
            </Text>
          </Paragraph>

          <Box my={4}>
            <IntegrationsTable integrations={integrations} />
          </Box>
        </Box>

        <Box mb={4}>
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
      </Box>
    );
  }
}

export default IntegrationsOverview;
