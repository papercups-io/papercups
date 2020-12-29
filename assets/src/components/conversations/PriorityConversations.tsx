import React from 'react';
import ConversationsContainer from './ConversationsContainer';
import {useConversations} from './ConversationsProvider';

const PriorityConversations = () => {
  const {
    loading,
    currentUser,
    account,
    isNewUser,
    priority = [],
    conversationsById = {},
    messagesByConversation = {},
    othersTypingByConversation = {},
    currentlyOnline = {},
    fetchPriorityConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
    handleTyping,
  } = useConversations();

  if (loading) {
    return null;
  }

  return (
    <ConversationsContainer
      loading={loading}
      title="Prioritized"
      account={account}
      currentUser={currentUser}
      currentlyOnline={currentlyOnline}
      showGetStarted={isNewUser}
      conversationIds={priority}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      othersTypingByConversation={othersTypingByConversation}
      fetch={fetchPriorityConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
      handleTyping={handleTyping}
    />
  );
};

export default PriorityConversations;
