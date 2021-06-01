import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Conversation, Message} from '../../types';
import * as API from '../../api';
import {useConversations} from './ConversationsProvider';
import ConversationHeader from './ConversationHeader';
import ConversationMessages from './ConversationMessages';
import ConversationFooter from './ConversationFooter';
import ConversationDetailsSidebar from './ConversationDetailsSidebar';
import logger from '../../logger';

const ConversationContainer = ({
  loading,
  selectedConversationId,
  isClosing,
  setScrollRef,
  onAssignUser,
  onMarkPriority,
  onRemovePriority,
  onCloseConversation,
  onReopenConversation,
  onDeleteConversation,
  onSendMessage,
}: {
  loading: boolean;
  selectedConversationId: string | null;
  isClosing: boolean;
  // TODO: handle scrolling within this component?
  setScrollRef: (el: any) => void;
  onAssignUser: (conversationId: string, userId: string | null) => void;
  onMarkPriority: (conversationId: string) => void;
  onRemovePriority: (conversationId: string) => void;
  onCloseConversation: (conversationId: string) => void;
  onReopenConversation: (conversationId: string) => void;
  onDeleteConversation: (conversationId: string) => void;
  onSendMessage: (message: Partial<Message>) => void;
}) => {
  // TODO: handle loading better?
  const {
    currentUser,
    account,
    conversationsById,
    messagesByConversation,
    isNewUser,
    isCustomerOnline,
  } = useConversations();
  const [history, setConversationHistory] = React.useState<Array<Conversation>>(
    []
  );
  const [
    isLoadingPreviousConversation,
    setLoadingPreviousConversation,
  ] = React.useState(false);
  const [
    hasPreviousConversations,
    setHasPreviousConversations,
  ] = React.useState(false);

  React.useEffect(() => {
    setConversationHistory([]);
    setLoadingPreviousConversation(false);
    setHasPreviousConversations(false);

    if (!selectedConversationId) {
      return;
    }

    API.fetchPreviousConversation(selectedConversationId)
      .then((conversation) => setHasPreviousConversations(!!conversation))
      .catch((err) =>
        logger.error('Error retrieving previous conversation:', err)
      );
  }, [selectedConversationId]);

  const users = (account && account.users) || [];
  const messages = selectedConversationId
    ? messagesByConversation[selectedConversationId]
    : [];
  const conversation = selectedConversationId
    ? conversationsById[selectedConversationId]
    : null;
  const customer = conversation ? conversation.customer : null;
  const isOnline = customer ? isCustomerOnline(customer.id) : false;

  const fetchPreviousConversation = async (conversationId: string) => {
    if (!selectedConversationId) {
      return;
    }

    setLoadingPreviousConversation(true);

    API.fetchPreviousConversation(conversationId)
      .then((conversation) => {
        const previousConversationId = conversation && conversation.id;

        if (previousConversationId) {
          setConversationHistory([conversation, ...history]);

          return API.fetchPreviousConversation(previousConversationId);
        }

        return null;
      })
      .then((conversation) => setHasPreviousConversations(!!conversation))
      .catch((err) =>
        logger.error('Error retrieving previous conversation:', err)
      )
      .finally(() => setLoadingPreviousConversation(false));
  };

  return (
    <>
      <ConversationHeader
        conversation={conversation}
        users={users}
        onAssignUser={onAssignUser}
        onMarkPriority={onMarkPriority}
        onRemovePriority={onRemovePriority}
        onCloseConversation={onCloseConversation}
        onReopenConversation={onReopenConversation}
        onDeleteConversation={onDeleteConversation}
      />
      <Flex
        sx={{
          position: 'relative',
          flex: 1,
          flexDirection: 'column',
          minHeight: 0,
          minWidth: 640,
          pr: 240, // TODO: animate this if we make it toggle-able
        }}
      >
        <ConversationMessages
          conversationId={selectedConversationId}
          account={account}
          messages={messages}
          history={history}
          currentUser={currentUser}
          loading={loading}
          isClosing={isClosing}
          isLoadingPreviousConversation={isLoadingPreviousConversation}
          hasPreviousConversations={hasPreviousConversations}
          // TODO: move "Getting started" UI out of this component
          showGetStarted={isNewUser}
          setScrollRef={setScrollRef}
          onLoadPreviousConversation={fetchPreviousConversation}
        />

        {conversation && (
          // NB: the `key` forces a rerender so the input can clear
          // any text from the last conversation and trigger autofocus
          <ConversationFooter
            key={conversation.id}
            onSendMessage={onSendMessage}
            currentUser={currentUser}
          />
        )}

        {customer && conversation && (
          <Box
            sx={{
              width: 240,
              height: '100%',
              overflowY: 'scroll',
              position: 'absolute',
              right: 0,
            }}
          >
            <ConversationDetailsSidebar
              customer={customer}
              conversation={conversation}
              isOnline={isOnline}
            />
          </Box>
        )}
      </Flex>
    </>
  );
};

export default ConversationContainer;
