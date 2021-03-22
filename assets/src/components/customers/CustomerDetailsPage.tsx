import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {colors, shadows, Button, Empty, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {Conversation, Customer} from '../../types';
import Spinner from '../Spinner';
import logger from '../../logger';
import {getColorByUuid} from '../conversations/support';
import ConversationItem from '../conversations/ConversationItem';
import {CustomerDetails} from '../conversations/ConversationDetailsSidebar';
import {sortConversationMessages} from '../../utils';

const DetailsSectionCard = ({children}: {children: any}) => {
  return (
    <Box
      p={3}
      mb={3}
      sx={{
        bg: colors.white,
        border: '1px solid rgba(0,0,0,.06)',
        borderRadius: 4,
        boxShadow: shadows.medium,
      }}
    >
      {children}
    </Box>
  );
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading?: boolean;
  customer: Customer | null;
  conversations: Array<Conversation>;
};

class CustomerDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    customer: null,
    conversations: [],
  };

  async componentDidMount() {
    try {
      const {id: customerId} = this.props.match.params;
      const customer = await API.fetchCustomer(customerId, {
        expand: ['company', 'tags'],
      });
      const conversations = await API.fetchConversations({
        customer_id: customerId,
      });

      this.setState({customer, conversations, loading: false});
    } catch (err) {
      logger.error('Error loading customer!', err);

      this.setState({loading: false});
    }
  }

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

  render() {
    const {loading, customer, conversations = []} = this.state;

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
          bg: 'rgb(245, 245, 245)',
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
        </Flex>

        <Flex>
          <Box sx={{flex: 1, pr: 4, mt: -2}}>
            <CustomerDetails customer={customer} />
          </Box>

          <Box sx={{flex: 3}}>
            <DetailsSectionCard>
              <Box pb={2} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
                <Title level={4}>Conversations</Title>
              </Box>

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
