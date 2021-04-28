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
import ConversationModal from '../conversations/ConversationModal';
import {sortConversationMessages} from '../../utils';

type Props = {customerId: string; history: History};
type State = {
  conversations: Conversation[];
  selectedConversationId: string | null;
  isModalVisible: boolean;
  isLoading: boolean;
};

class CustomerDetailsConversations extends React.Component<Props, State> {
  state: State = {
    conversations: [],
    selectedConversationId: null,
    isModalVisible: false,
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
    this.setState({
      selectedConversationId: conversationId,
      isModalVisible: true,
    });
  };

  handleCloseConversationModal = () => {
    // TODO: figure out a better way to ensure that conversations are up to date
    // (we probably want to use the ConversationsProvider to listen for updates)
    this.fetchConversations();
    this.setState({selectedConversationId: null, isModalVisible: false});
  };

  render() {
    const {customerId} = this.props;
    const {
      isLoading,
      isModalVisible,
      conversations,
      selectedConversationId,
    } = this.state;

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
            onInitializeNewConversation={this.fetchConversations}
          />
        </Flex>
        {isLoading && conversations.length === 0 && (
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
        )}
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

        {selectedConversationId && (
          <ConversationModal
            visible={isModalVisible}
            conversationId={selectedConversationId}
            onClose={this.handleCloseConversationModal}
          />
        )}
      </>
    );
  }
}

export default CustomerDetailsConversations;
