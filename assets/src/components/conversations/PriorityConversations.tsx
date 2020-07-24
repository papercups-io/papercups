import React from 'react';
import ConversationsWrapper from './ConversationsWrapper';
import {useConversations} from './ConversationsProvider';

const PriorityConversations = () => {
  const {
    loading,
    currentUser,
    account,
    // showGetStarted, // FIXME
    selectedConversationId,
    priority = [],
    conversationsById = {},
    messagesByConversation = {},
    fetchPriorityConversations,
    onSelectConversation,
    onUpdateConversation,
    onSendMessage,
  } = useConversations();

  if (loading) {
    return null;
  }

  return (
    <ConversationsWrapper
      loading={loading}
      title="Prioritized"
      account={account}
      currentUser={currentUser}
      showGetStarted={false}
      selectedConversationId={selectedConversationId}
      conversationIds={priority}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      fetch={fetchPriorityConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default PriorityConversations;
