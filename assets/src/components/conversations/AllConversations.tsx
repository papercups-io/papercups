import React from 'react';
import {useConversations} from './ConversationsProvider';
import ConversationsContainer from './ConversationsContainer';

const AllConversations = () => {
  const {
    loading,
    currentUser,
    account,
    isNewUser,
    all = [],
    conversationsById = {},
    messagesByConversation = {},
    currentlyOnline = {},
    fetchAllConversations,
    onSelectConversation,
    onUpdateConversation,
    onSendMessage,
  } = useConversations();

  if (loading) {
    return null;
  }

  return (
    <ConversationsContainer
      loading={loading}
      title="All conversations"
      account={account}
      currentUser={currentUser}
      currentlyOnline={currentlyOnline}
      showGetStarted={isNewUser}
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
