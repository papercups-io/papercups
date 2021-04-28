import React from 'react';
import {Flex} from 'theme-ui';
import {colors} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import ConversationMessages from '../conversations/ConversationMessages';
import ConversationFooter from '../conversations/ConversationFooter';
import {Conversation, Message, User} from '../../types';

type Props = {
  conversation: Conversation;
  currentUser: User | null;
  messages: Array<Message>;
  onSendMessage: (message: Partial<Message>, cb: () => void) => void;
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

  handleSendMessage = (message: Partial<Message>) => {
    const {id: conversationId} = this.props.conversation;

    if (!conversationId) {
      return null;
    }

    this.props.onSendMessage(
      {...message, conversation_id: conversationId},
      () => {
        this.scrollIntoView();
      }
    );
  };

  render() {
    const {currentUser, messages = []} = this.props;

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
          setScrollRef={(el) => (this.scrollToEl = el)}
        />

        <ConversationFooter
          sx={{px: 3, pb: 3}}
          onSendMessage={this.handleSendMessage}
        />
      </Flex>
    );
  }
}

const ConversationSidebarWrapper = ({
  conversationId,
}: {
  conversationId: string;
}) => {
  const {
    loading,
    currentUser,
    conversationsById = {},
    messagesByConversation = {},
    fetchConversationById,
    onSendMessage,
    onSelectConversation,
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
    />
  );
};

export default ConversationSidebarWrapper;
