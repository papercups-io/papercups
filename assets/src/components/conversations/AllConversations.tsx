import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsContainer from './ConversationsContainer';

const AllConversations = () => {
  const {
    loading,
    currentUser,
    account,
    isNewUser,
    all = [],
    conversationsById = {},
    messagesByConversation = {},
    othersTypingByConversation = {},
    currentlyOnline = {},
    fetchAllConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
    handleTyping,
  } = useConversations();

  return (
    <ConversationsContainer
      loading={loading}
      title="All conversations"
      account={account}
      currentUser={currentUser}
      currentlyOnline={currentlyOnline}
      showGetStarted={isNewUser}
      conversationIds={all}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      othersTypingByConversation={othersTypingByConversation}
      fetch={fetchAllConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
      handleTyping={handleTyping}
    />
  );
};

export default AllConversations;
