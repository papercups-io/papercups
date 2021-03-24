import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';
import * as API from '../../api';

const MyConversations = () => {
  const {
    loading,
    currentUser,
    account,
    mine = [],
    messagesByConversation = {},
    onSetMyConversations,
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
      conversationIds={mine}
      messagesByConversation={messagesByConversation}
      fetcher={fetcher}
      onRetrieveConversations={onSetMyConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default MyConversations;
