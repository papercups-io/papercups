import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';
import * as API from '../../api';

const MyConversations = () => {
  const {
    loading,
    currentUser,
    account,
    messagesByConversation = {},
    inboxes,
    onSetConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
  } = useConversations();

  if (!currentUser) {
    return null;
  }

  const {id: userId} = currentUser;
  const fetcher = (query = {}) => API.fetchMyConversations(userId, query);

  return (
    <ConversationsDashboard
      loading={loading}
      title="Assigned to me"
      account={account}
      conversationIds={inboxes.all.assigned}
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

export default MyConversations;
