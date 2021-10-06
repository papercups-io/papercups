import React from 'react';
import {Link} from 'react-router-dom';
import {Flex} from 'theme-ui';
import {colors, Button, Modal} from '../common';
import {useConversations} from './ConversationsProvider';
import ConversationMessages from '../conversations/ConversationMessages';
import ConversationFooter from '../conversations/ConversationFooter';
import {Conversation, Message, User} from '../../types';
import {useAuth} from '../auth/AuthProvider';

type Props = {
  visible?: boolean;
  conversation: Conversation;
  currentUser: User | null;
  messages: Array<Message>;
  onClose: () => void;
};

class ConversationModal extends React.Component<Props> {
  scrollToEl: any;

  componentDidUpdate(prev: Props) {
    if (
      this.props.messages.length > prev.messages.length ||
      (this.props.visible && !prev.visible)
    ) {
      this.scrollIntoView();
    }
  }

  scrollIntoView = () => {
    this.scrollToEl && this.scrollToEl.scrollIntoView();
  };

  handleSetScrollRef = (el: HTMLDivElement | null) => {
    this.scrollToEl = el;

    if (el) {
      this.scrollIntoView();
    }
  };

  render() {
    const {
      visible,
      conversation,
      currentUser,
      messages = [],
      onClose,
    } = this.props;
    const {id, status, customer} = conversation;
    const identifer = customer.name || customer.email || 'Anonymous User';
    const title = `Conversation with ${identifer}`;
    const href =
      status === 'closed'
        ? `/conversations/closed/${id}`
        : `/conversations/all/${id}`;

    return (
      <Modal
        title={title}
        visible={visible}
        bodyStyle={{padding: 0}}
        onCancel={onClose}
        footer={
          <Flex>
            <Link to={href}>
              <Button key="submit">View in dashboard</Button>
            </Link>
          </Flex>
        }
      >
        <Flex
          sx={{
            width: '100%',
            height: '64vh',
            flexDirection: 'column',
            bg: colors.white,
            flex: 1,
          }}
        >
          <ConversationMessages
            messages={messages}
            currentUser={currentUser}
            setScrollRef={this.handleSetScrollRef}
          />

          <ConversationFooter
            sx={{px: 3, pb: 3}}
            conversationId={conversation.id}
            onSendMessage={this.scrollIntoView}
          />
        </Flex>
      </Modal>
    );
  }
}

const ConversationModalWrapper = ({
  visible,
  conversationId,
  onClose,
}: {
  visible?: boolean;
  conversationId: string;
  onClose: () => void;
}) => {
  const {currentUser} = useAuth();
  const {
    loading,
    fetchConversationById,
    getConversationById,
  } = useConversations();

  React.useEffect(() => {
    fetchConversationById(conversationId);
    // eslint-disable-next-line
  }, [conversationId]);

  if (loading) {
    return null;
  }

  const conversation = getConversationById(conversationId);

  if (!conversation) {
    return null;
  }

  const {messages = []} = conversation;

  return (
    <ConversationModal
      visible={visible}
      conversation={conversation}
      messages={messages}
      currentUser={currentUser}
      onClose={onClose}
    />
  );
};

export const ConversationModalRenderer = ({
  children,
  conversationId,
  onClose,
}: {
  children: (handleOpenModal: () => void) => React.ReactElement;
  conversationId: string | null;
  onClose?: () => void;
}) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenConversationModal = () => setModalOpen(true);
  const handleCloseConversationModal = () => setModalOpen(false);

  const handleClose = () => {
    if (typeof onClose === 'function') {
      onClose();
    }

    handleCloseConversationModal();
  };

  if (!conversationId) {
    return children(handleOpenConversationModal);
  }

  return (
    <React.Fragment>
      {children(handleOpenConversationModal)}

      <ConversationModalWrapper
        conversationId={conversationId}
        visible={isModalOpen}
        onClose={handleClose}
      />
    </React.Fragment>
  );
};

export default ConversationModalWrapper;
