import React from 'react';
import {History} from 'history';
import {Flex} from 'theme-ui';
import {Empty} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import {Conversation} from '../../types';
import {getColorByUuid} from '../conversations/support';
import ConversationItem from '../conversations/ConversationItem';
import StartConversationButton from '../conversations/StartConversationButton';
import {sortConversationMessages} from '../../utils';

type Props = {customerId: string; history: History};
type State = {
  conversations: Conversation[];
  isLoading: boolean;
};

class CustomerDetailsConversations extends React.Component<Props, State> {
  state: State = {
    conversations: [],
    isLoading: true,
  };

  componentDidMount() {
    this.fetchConversations();
  }

  hasOpenConversation = () => {
    const openConversation = this.state.conversations.find(
      (conversation) => conversation.status === 'open'
    );

    return !!openConversation;
  };

  fetchConversations = async () => {
    this.setState({isLoading: true});

    const {data: conversations} = await API.fetchConversations({
      customer_id: this.props.customerId,
    });

    this.setState({conversations, isLoading: false});
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

  render() {
    const {customerId} = this.props;
    const {isLoading, conversations} = this.state;

    if (isLoading) {
      return (
        <Flex
          p={4}
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
      <>
        <Flex
          p={3}
          sx={{
            justifyContent: 'flex-end',
          }}
        >
          <StartConversationButton
            customerId={customerId}
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
      </>
    );
  }
}

export default CustomerDetailsConversations;
