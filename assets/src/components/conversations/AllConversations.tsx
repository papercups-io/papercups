import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsDashboard from './ConversationsDashboard';

const AllConversations = () => {
  const {
    loading,
    currentUser,
    account,
    all = [],
    messagesByConversation = {},
    fetchAllConversations,
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
      fetch={fetchAllConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default AllConversations;
