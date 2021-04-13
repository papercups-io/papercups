import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {notification, Button, Empty, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {BrowserSession, Conversation, Customer} from '../../types';
import Spinner from '../Spinner';
import logger from '../../logger';
import {getColorByUuid} from '../conversations/support';
import ConversationItem from '../conversations/ConversationItem';
import StartConversationButton from '../conversations/StartConversationButton';
import CustomerDetailsSidebar from './CustomerDetailsSidebar';
import {sortConversationMessages} from '../../utils';
import CustomerDetailsCard from './CustomerDetailsCard';
import EditCustomerDetailsModal from './EditCustomerDetailsModal';

type Props = RouteComponentProps<{id: string}>;
type State = {
  conversations: Array<Conversation>;
  customer: Customer | null;
  loading?: boolean;
  session: BrowserSession | null;
  isEditModalVisible: boolean;
};

class CustomerDetailsPage extends React.Component<Props, State> {
  state: State = {
    conversations: [],
    customer: null,
    loading: true,
    session: null,
    isEditModalVisible: false,
  };

  async componentDidMount() {
    try {
      const [customer, conversations, session] = await Promise.all([
        this.fetchCustomer(),
        this.fetchConversations(),
        this.fetchSession(),
      ]);

      this.setState({customer, conversations, session, loading: false});
    } catch (err) {
      logger.error('Error loading customer or conversations!', err);

      this.setState({loading: false});
    }
  }

  getCustomerId = () => this.props.match.params.id;

  fetchCustomer = async () => {
    return await API.fetchCustomer(this.getCustomerId(), {
      expand: ['company', 'tags'],
    });
  };

  fetchConversations = async () => {
    const {data: conversations} = await API.fetchConversations({
      customer_id: this.getCustomerId(),
    });

    return conversations;
  };

  fetchSession = async () => {
    const sessions = await API.fetchBrowserSessions({
      customerId: this.getCustomerId(),
      isActive: true,
      limit: 1,
    });
    const session = sessions[0];

    return session;
  };

  refetchConversations = async () => {
    const conversations = await this.fetchConversations();
    this.setState({conversations});
  };

  hasOpenConversation = () => {
    const openConversation = this.state.conversations.find(
      (conversation) => conversation.status === 'open'
    );

    return !!openConversation;
  };

  handleSelectConversation = (conversationId: string) => {
    const conversation = this.state.conversations.find(
      (conversation) => conversation.id === conversationId
    );
    const isClosed = conversation && conversation.status === 'closed';
    const url = isClosed
      ? `/conversations/closed?cid=${conversationId}`
      : `/conversations/all?cid=${conversationId}`;

    this.props.history.push(url);
  };

  handleCustomerUpdated = async () => {
    const customer = await this.fetchCustomer();
    this.setState({customer});
    this.toggleIsEditModalVisible(false);
    notification.success({
      message: `Customer successfully updated!`,
      duration: 10,
    });
  };

  toggleIsEditModalVisible = (isEditModalVisible: boolean) => {
    this.setState({isEditModalVisible});
  };

  render() {
    const {
      conversations = [],
      customer,
      isEditModalVisible,
      loading,
      session,
    } = this.state;

    // TODO: add error handling when customer can't be loaded
    if (loading || !customer) {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
            bg: 'rgb(245, 245, 245)',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    }

    return (
      <Flex
        p={4}
        sx={{
          flexDirection: 'column',
          flex: 1,
          height: '100v',
          bg: 'rgb(245, 245, 245)',
        }}
      >
        <Flex mb={4}>
          <Link to="/customers">
            <Button icon={<ArrowLeftOutlined />}>Back to customers</Button>
          </Link>
        </Flex>

        <Box sx={{height: '100%'}}>
          <Flex sx={{flexDirection: 'row-reverse'}} mb={3}>
            <Button
              type="primary"
              onClick={() => this.toggleIsEditModalVisible(true)}
            >
              Edit
            </Button>
            <EditCustomerDetailsModal
              customer={customer}
              isVisible={isEditModalVisible}
              onClose={() => this.toggleIsEditModalVisible(false)}
              onUpdate={this.handleCustomerUpdated}
            />
          </Flex>
          <Flex sx={{height: '100%'}}>
            <Box mr={3}>
              <CustomerDetailsSidebar customer={customer} session={session} />
            </Box>

            <Box sx={{flex: 3}}>
              <CustomerDetailsCard>
                <Flex
                  p={3}
                  sx={{
                    borderBottom: '1px solid rgba(0,0,0,.06)',
                    justifyContent: 'space-between',
                  }}
                >
                  <Title level={4}>Conversations</Title>
                  <StartConversationButton
                    customerId={this.getCustomerId()}
                    isDisabled={this.hasOpenConversation()}
                    onInitializeNewConversation={this.refetchConversations}
                  />
                </Flex>

                {conversations.length > 0 ? (
                  conversations.map((conversation) => {
                    const {
                      id: conversationId,
                      customer_id: customerId,
                      messages = [],
                    } = conversation;
                    const color = getColorByUuid(customerId);
                    const sorted = sortConversationMessages(messages);

                    return (
                      <ConversationItem
                        key={conversationId}
                        conversation={conversation}
                        messages={sorted}
                        color={color}
                        onSelectConversation={this.handleSelectConversation}
                      />
                    );
                  })
                ) : (
                  <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} />
                )}
              </CustomerDetailsCard>
            </Box>
          </Flex>
        </Box>
      </Flex>
    );
  }
}

export default CustomerDetailsPage;
