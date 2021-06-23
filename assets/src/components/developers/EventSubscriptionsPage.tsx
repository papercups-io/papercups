import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Container, Paragraph, Text, Title} from '../common';
import {PlusOutlined} from '../icons';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {EventSubscription} from '../../types';
import WebhooksTable from '../integrations/WebhooksTable';
import NewWebhookModal from '../integrations/NewWebhookModal';

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  runkit: any;
  isWebhookModalOpen: boolean;
  selectedWebhook: EventSubscription | null;
  webhooks: Array<EventSubscription>;
  personalApiKey: string | null;
  accountId: string | null;
  apiExplorerOutput: any;
};

class EventSubscriptionsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    runkit: null,
    isWebhookModalOpen: false,
    selectedWebhook: null,
    webhooks: [],
    personalApiKey: null,
    accountId: null,
    apiExplorerOutput: null,
  };

  async componentDidMount() {
    try {
      const webhooks = await API.fetchEventSubscriptions();
      const personalApiKeys = await API.fetchPersonalApiKeys();
      const key =
        personalApiKeys.length > 0
          ? personalApiKeys[personalApiKeys.length - 1]
          : null;

      this.setState({
        webhooks,
        personalApiKey: key ? key.value : null,
        accountId: key ? key.account_id : null,
        loading: false,
      });
    } catch (err) {
      logger.error('Error loading event subscriptions:', err);

      this.setState({loading: false});
    }
  }

  handleAddWebhook = () => {
    this.setState({isWebhookModalOpen: true});
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

  refreshEventSubscriptions = async () => {
    try {
      const webhooks = await API.fetchEventSubscriptions();

      this.setState({webhooks});
    } catch (err) {
      logger.error('Error refreshing event subscriptions:', err);
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

  render() {
    const {
      loading,
      isWebhookModalOpen,
      selectedWebhook,
      webhooks = [],
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
      <Container>
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
      </Container>
    );
  }
}

export default EventSubscriptionsPage;
