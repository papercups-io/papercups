import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';
import * as API from '../../api';

const PriorityConversations = () => {
  const {
    loading,
    currentUser,
    account,
    inboxes,
    messagesByConversation = {},
    onSetConversations,
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
      conversationIds={inboxes.all.priority}
      messagesByConversation={messagesByConversation}
      fetcher={API.fetchPriorityConversations}
      onRetrieveConversations={onSetConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default PriorityConversations;
