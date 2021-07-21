import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';
import * as API from '../../api';

const MentionedConversations = () => {
  const {
    loading,
    currentUser,
    account,
    messagesByConversation = {},
    inboxes,
    onSetConversations,
    onSelectConversation,
    onUpdateConversation,
    onDeleteConversation,
    onSendMessage,
  } = useConversations();

  if (!currentUser) {
    return null;
  }

  const {id: userId} = currentUser;
  const fetcher = (query = {}) =>
    API.fetchMentionedConversations(userId, query);

  return (
    <ConversationsDashboard
      loading={loading}
      title="Mentions"
      account={account}
      conversationIds={inboxes.all.mentioned}
      messagesByConversation={messagesByConversation}
      fetcher={fetcher}
      onRetrieveConversations={onSetConversations}
      onSelectConversation={onSelectConversation}
      onUpdateConversation={onUpdateConversation}
      onDeleteConversation={onDeleteConversation}
      onSendMessage={onSendMessage}
    />
  );
};

export default MentionedConversations;
