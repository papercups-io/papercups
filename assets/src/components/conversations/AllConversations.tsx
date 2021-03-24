import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsDashboard from './ConversationsDashboard';
import * as API from '../../api';

const AllConversations = () => {
  const {
    loading,
    currentUser,
    account,
    all = [],
    messagesByConversation = {},
    onSetAllConversations,
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
      title="All conversations"
      account={account}
      conversationIds={all}
      messagesByConversation={messagesByConversation}
      fetcher={API.fetchAllConversations}
      onRetrieveConversations={onSetAllConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default AllConversations;
