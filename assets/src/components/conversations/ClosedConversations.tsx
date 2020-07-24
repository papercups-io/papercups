import React from 'react';
import ConversationsWrapper from './ConversationsWrapper';
import {useConversations} from './ConversationsProvider';

const ClosedConversations = () => {
  const {
    loading,
    currentUser,
    account,
    // showGetStarted, // FIXME
    selectedConversationId,
    closed = [],
    conversationsById = {},
    messagesByConversation = {},
    fetchClosedConversations,
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
      title={'Closed'}
      account={account}
      currentUser={currentUser}
      showGetStarted={false}
      selectedConversationId={selectedConversationId}
      conversationIds={closed}
      conversationsById={conversationsById}
      messagesByConversation={messagesByConversation}
      fetch={fetchClosedConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default ClosedConversations;
