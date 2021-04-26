import React from 'react';
import ConversationsDashboard from './ConversationsDashboard';
import {useConversations} from './ConversationsProvider';
import * as API from '../../api';

type Props = {
  source: string;
  title: string;
};

const ConversationsBySource = ({source, title}: Props) => {
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
    API.fetchMyConversations(userId, {...query, source});

  const inbox = inboxes.bySource[source];

  return (
    <ConversationsDashboard
      loading={loading}
      title={title}
      account={account}
      conversationIds={inbox?.conversationIds ?? []}
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

export default ConversationsBySource;
