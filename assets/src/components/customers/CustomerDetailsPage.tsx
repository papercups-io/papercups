import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Card, Empty, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {Conversation, Customer} from '../../types';
import Spinner from '../Spinner';
import logger from '../../logger';
import {getColorByUuid} from '../conversations/support';
import ConversationItem from '../conversations/ConversationItem';
import StartConversationButton from '../conversations/StartConversationButton';
import {CustomerDetails} from '../conversations/ConversationDetailsSidebar';
import {sortConversationMessages} from '../../utils';
import CustomerDetailsModal from '../customers/CustomerDetailsModal';

const DetailsSectionCard = ({children}: {children: any}) => {
  return <Card sx={{p: 3, mb: 3}}>{children}</Card>;
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading?: boolean;
  customer: Customer | null;
  conversations: Array<Conversation>;
  isModalOpen?: boolean;
};

class CustomerDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    customer: null,
    conversations: [],
    isModalOpen: false,
  };

  getCustomerId = () => this.props.match.params.id;

  async componentDidMount() {
    const customerId = this.getCustomerId();

    try {
      const customer = await API.fetchCustomer(customerId, {
        expand: ['company', 'tags'],
      });
      const {data: conversations} = await API.fetchConversations({
        customer_id: customerId,
      });

      this.setState({customer, conversations, loading: false});
    } catch (err) {
      logger.error('Error loading customer!', err);

      this.setState({loading: false});
    }
  }

  handleRefreshCustomer = async () => {
    try {
      const customer = await API.fetchCustomer(this.getCustomerId(), {
        expand: ['company', 'tags'],
      });

      this.setState({customer, loading: false});
    } catch (err) {
      logger.error('Error loading customer!', err);

      this.setState({loading: false});
    }
  };

  fetchConversations = async () => {
    try {
      const {data: conversations} = await API.fetchConversations({
        customer_id: this.getCustomerId(),
      });

      this.setState({conversations});
    } catch (err) {
      logger.error('Error loading conversations!', err);
    }
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

  handleOpenModal = () => {
    this.setState({isModalOpen: true});
  };

  handleCloseModal = () => {
    this.setState({isModalOpen: false});
  };

  handleCustomerUpdated = async () => {
    return this.handleRefreshCustomer().then(() => this.handleCloseModal());
  };

  handleCustomerDeleted = () => {
    this.props.history.push('/customers');
  };

  render() {
    const {loading, isModalOpen, customer, conversations = []} = this.state;

    if (loading || !customer) {
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

    const {name, email} = customer;
    const title = name || email || 'Anonymous User';

    return (
      <Flex
        p={4}
        sx={{
          flexDirection: 'column',
          flex: 1,
          bg: 'rgb(250, 250, 250)',
        }}
      >
        <Flex
          mb={4}
          sx={{justifyContent: 'space-between', alignItems: 'center'}}
        >
          <Link to="/customers">
            <Button icon={<ArrowLeftOutlined />}>Back to all customers</Button>
          </Link>
        </Flex>

        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={2}>{title}</Title>

          <Button type="primary" onClick={this.handleOpenModal}>
            Edit
          </Button>
        </Flex>

        <CustomerDetailsModal
          customer={customer}
          isVisible={isModalOpen}
          onClose={this.handleCloseModal}
          onUpdate={this.handleCustomerUpdated}
          onDelete={this.handleCustomerDeleted}
        />

        <Flex>
          <Box sx={{flex: 1, pr: 4, mt: -2}}>
            <CustomerDetails customer={customer} />
          </Box>

          <Box sx={{flex: 3}}>
            <DetailsSectionCard>
              <Flex
                pb={2}
                sx={{
                  borderBottom: '1px solid rgba(0,0,0,.06)',
                  justifyContent: 'space-between',
                }}
              >
                <Title level={4}>Conversations</Title>
                <StartConversationButton
                  customerId={this.getCustomerId()}
                  isDisabled={this.hasOpenConversation()}
                  onInitializeNewConversation={this.fetchConversations}
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
            </DetailsSectionCard>
          </Box>
        </Flex>
      </Flex>
    );
  }
}

export default CustomerDetailsPage;
