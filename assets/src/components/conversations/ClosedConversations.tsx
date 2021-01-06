import React from 'react';
import ConversationsContainer from './ConversationsContainer';
import {useConversations} from './ConversationsProvider';

const ClosedConversations = () => {
  const {
    loading,
    currentUser,
    account,
    isNewUser,
    closed = [],
    conversationsById = {},
    messagesByConversation = {},
    othersTypingByConversation = {},
    currentlyOnline = {},
    fetchAllConversations,
    fetchClosedConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
    handleTyping,
  } = useConversations();

  const fetch = async () => {
    const results = await fetchClosedConversations();
    // Need to refresh the cache for the edge case where we re-open a
    // conversation and then want to view in-app notifications for it.
    await fetchAllConversations();

    return results;
  };

  return (
    <ConversationsContainer
      loading={loading}
      title="Closed"
      account={account}
      currentUser={currentUser}
      currentlyOnline={currentlyOnline}
      showGetStarted={isNewUser}
      conversationIds={closed}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      othersTypingByConversation={othersTypingByConversation}
      fetch={fetch}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
      handleTyping={handleTyping}
    />
  );
};

export default ClosedConversations;
