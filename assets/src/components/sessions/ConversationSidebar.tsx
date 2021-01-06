import React from 'react';
import {Flex} from 'theme-ui';
import {colors} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import ConversationMessages from '../conversations/ConversationMessages';
import ConversationFooter from '../conversations/ConversationFooter';
import {Conversation, Message, User} from '../../types';

type Props = {
  conversation: Conversation;
  currentUser: User;
  messages: Array<Message>;
  othersTyping: Array<any>;
  onSendMessage: (
    message: string,
    conversationId: string,
    cb: () => void
  ) => void;
  handleTyping: (conversationId: string) => () => void;
};

class ConversationSidebar extends React.Component<Props, any> {
  scrollToEl: any;

  componentDidMount() {
    this.scrollIntoView();
  }

  componentDidUpdate(prev: Props) {
    const {messages: previousMessages} = prev;
    const {messages} = this.props;

    if (messages.length > previousMessages.length) {
      this.scrollIntoView();
    }
  }

  scrollIntoView = () => {
    this.scrollToEl && this.scrollToEl.scrollIntoView();
  };

  handleSendMessage = (message: string) => {
    const {id: conversationId} = this.props.conversation;

    if (!conversationId) {
      return null;
    }

    this.props.onSendMessage(message, conversationId, () => {
      this.scrollIntoView();
    });
  };

  render() {
    const {conversation, currentUser, messages = []} = this.props;
    const {customer} = conversation;

    return (
      <Flex
        className="rr-block"
        sx={{
          width: '100%',
          height: '100%',
          flexDirection: 'column',
          bg: colors.white,
          border: `1px solid rgba(0,0,0,.06)`,
          boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 4px',
          flex: 1,
        }}
      >
        <ConversationMessages
          sx={{p: 3}}
          messages={messages}
          currentUser={currentUser}
          customer={customer}
          setScrollRef={(el) => (this.scrollToEl = el)}
        />

        <ConversationFooter
          sx={{px: 3, pb: 3}}
          onSendMessage={this.handleSendMessage}
          onInputChanged={this.props.handleTyping(conversation.id)}
          othersTyping={this.props.othersTyping}
        />
      </Flex>
    );
  }
}

const ConversationsSidebarWrapper = ({
  conversationId,
}: {
  conversationId: string;
}) => {
  const {
    loading,
    currentUser,
    conversationsById = {},
    messagesByConversation = {},
    othersTypingByConversation = {},
    fetchConversationById,
    onSendMessage,
    onSelectConversation,
    handleTyping,
  } = useConversations();

  React.useEffect(() => {
    fetchConversationById(conversationId).then(() =>
      onSelectConversation(conversationId)
    );
    // eslint-disable-next-line
  }, [conversationId]);

  if (loading) {
    return null;
  }

  const othersTyping = othersTypingByConversation[conversationId] || [];

  // TODO: fix case where conversation is closed!
  const conversation = conversationsById[conversationId] || null;
  const messages = messagesByConversation[conversationId] || null;

  if (!conversation || !messages) {
    return null;
  }

  return (
    <ConversationSidebar
      conversation={conversation}
      messages={messages}
      currentUser={currentUser}
      onSendMessage={onSendMessage}
      handleTyping={handleTyping}
      othersTyping={othersTyping}
    />
  );
};

export default ConversationsSidebarWrapper;
