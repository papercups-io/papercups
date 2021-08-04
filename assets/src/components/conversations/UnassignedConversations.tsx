import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsDashboard from './ConversationsDashboard';
import * as API from '../../api';

const UnassignedConversations = () => {
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
      title="Unassigned"
      account={account}
      conversationIds={inboxes.all.unassigned}
      messagesByConversation={messagesByConversation}
      fetcher={API.fetchUnassignedConversations}
      onRetrieveConversations={onSetConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default UnassignedConversations;
