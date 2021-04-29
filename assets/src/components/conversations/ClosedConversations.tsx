import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';
import * as API from '../../api';

const ClosedConversations = () => {
  const {
    loading,
    currentUser,
    account,
    inboxes,
    messagesByConversation = {},
    fetchAllConversations,
    onSetConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
  } = useConversations();

  const fetcher = async (query = {}) => {
    const results = await API.fetchClosedConversations(query);
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
      conversationIds={inboxes.all.closed}
      messagesByConversation={messagesByConversation}
      fetcher={fetcher}
      onRetrieveConversations={onSetConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default ClosedConversations;
