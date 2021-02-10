import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';

const MyConversations = () => {
  const {
    loading,
    currentUser,
    account,
    mine = [],
    messagesByConversation = {},
    fetchMyConversations,
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
      title="Assigned to me"
      account={account}
      conversationIds={mine}
      messagesByConversation={messagesByConversation}
      fetch={fetchMyConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default MyConversations;
