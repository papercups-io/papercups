import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';

const PriorityConversations = () => {
  const {
    loading,
    currentUser,
    account,
    priority = [],
    messagesByConversation = {},
    fetchPriorityConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
  } = useConversations();

  if (!currentUser) {
    return null;
  }

  return (
    <ConversationsDashboard
      loading={loading}
      title="Prioritized"
      account={account}
      conversationIds={priority}
      messagesByConversation={messagesByConversation}
      fetch={fetchPriorityConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default PriorityConversations;
