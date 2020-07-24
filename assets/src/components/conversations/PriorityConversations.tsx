import React from 'react';
import ConversationsContainer from './ConversationsContainer';
import {useConversations} from './ConversationsProvider';

const PriorityConversations = () => {
  const {
    loading,
    currentUser,
    account,
    // showGetStarted, // FIXME
    priority = [],
    conversationsById = {},
    messagesByConversation = {},
    fetchPriorityConversations,
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
      title="Prioritized"
      account={account}
      currentUser={currentUser}
      showGetStarted={false}
      conversationIds={priority}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      fetch={fetchPriorityConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default PriorityConversations;
