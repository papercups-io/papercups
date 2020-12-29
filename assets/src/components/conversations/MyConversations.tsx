import React from 'react';
import ConversationsContainer from './ConversationsContainer';
import {useConversations} from './ConversationsProvider';

const MyConversations = () => {
  const {
    loading,
    currentUser,
    account,
    isNewUser,
    mine = [],
    conversationsById = {},
    messagesByConversation = {},
    othersTypingByConversation = {},
    currentlyOnline = {},
    fetchMyConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
    handleTyping,
  } = useConversations();

  if (loading) {
    return null;
  }

  return (
    <ConversationsContainer
      loading={loading}
      title="Assigned to me"
      account={account}
      currentUser={currentUser}
      currentlyOnline={currentlyOnline}
      showGetStarted={isNewUser}
      conversationIds={mine}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      othersTypingByConversation={othersTypingByConversation}
      fetch={fetchMyConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
      handleTyping={handleTyping}
    />
  );
};

export default MyConversations;
