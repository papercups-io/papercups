import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsWrapper from './ConversationsWrapper';

const AllConversations = () => {
  const {
    loading,
    currentUser,
    account,
    // showGetStarted, // FIXME
    selectedConversationId,
    all = [],
    conversationsById = {},
    messagesByConversation = {},
    fetchAllConversations,
    onSelectConversation,
    onUpdateConversation,
    onSendMessage,
  } = useConversations();

  if (loading) {
    return null;
  }

  return (
    <ConversationsWrapper
      loading={loading}
      title="All conversations"
      account={account}
      currentUser={currentUser}
      showGetStarted={false}
      selectedConversationId={selectedConversationId}
      conversationIds={all}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      fetch={fetchAllConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default AllConversations;
