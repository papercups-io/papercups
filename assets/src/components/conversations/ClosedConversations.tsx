import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';

const ClosedConversations = () => {
  const {
    loading,
    currentUser,
    account,
    closed = [],
    messagesByConversation = {},
    fetchAllConversations,
    fetchClosedConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
  } = useConversations();

  const fetch = async () => {
    const results = await fetchClosedConversations();
    // Need to refresh the cache for the edge case where we re-open a
    // conversation and then want to view in-app notifications for it.
    await fetchAllConversations();

    return results;
  };

  if (!currentUser) {
    return null;
  }

  return (
    <ConversationsDashboard
      loading={loading}
      title="Closed"
      account={account}
      conversationIds={closed}
      messagesByConversation={messagesByConversation}
      fetch={fetch}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default ClosedConversations;
