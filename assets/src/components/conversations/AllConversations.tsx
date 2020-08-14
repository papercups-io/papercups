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
    onDeleteConversation,
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
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default AllConversations;
