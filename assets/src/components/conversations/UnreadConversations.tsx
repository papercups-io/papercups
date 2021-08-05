import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsDashboard from './ConversationsDashboard';
import * as API from '../../api';

const UnreadConversations = () => {
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
      title="All unread"
      account={account}
      conversationIds={inboxes.all.unread}
      messagesByConversation={messagesByConversation}
      fetcher={API.fetchUnreadConversations}
      onRetrieveConversations={onSetConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default UnreadConversations;
