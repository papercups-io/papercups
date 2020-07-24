import React from 'react';
import ConversationsContainer from './ConversationsContainer';
import {useConversations} from './ConversationsProvider';

const MyConversations = () => {
  const {
    loading,
    currentUser,
    account,
    // showGetStarted, // FIXME
    mine = [],
    conversationsById = {},
    messagesByConversation = {},
    fetchMyConversations,
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
      title="Assigned to me"
      account={account}
      currentUser={currentUser}
      showGetStarted={false}
      conversationIds={mine}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      fetch={fetchMyConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default MyConversations;
