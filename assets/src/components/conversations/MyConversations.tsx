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
    currentlyOnline = {},
    fetchMyConversations,
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
      title="Assigned to me"
      account={account}
      currentUser={currentUser}
      currentlyOnline={currentlyOnline}
      showGetStarted={isNewUser}
      conversationIds={mine}
      conversationsById={conversationsById}
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
