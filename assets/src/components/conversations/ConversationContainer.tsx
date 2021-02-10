import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Message} from '../../types';
import {useConversations} from './ConversationsProvider';
import ConversationHeader from './ConversationHeader';
import ConversationMessages from './ConversationMessages';
import ConversationFooter from './ConversationFooter';
import ConversationDetailsSidebar from './ConversationDetailsSidebar';

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
  onAssignUser: (conversationId: string, userId: string) => void;
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

  const users = (account && account.users) || [];
  const messages = selectedConversationId
    ? messagesByConversation[selectedConversationId]
    : [];
  const conversation = selectedConversationId
    ? conversationsById[selectedConversationId]
    : null;
  const customer = conversation ? conversation.customer : null;
  const isOnline = customer ? isCustomerOnline(customer.id) : false;

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
          messages={messages}
          currentUser={currentUser}
          loading={loading}
          isClosing={isClosing}
          showGetStarted={isNewUser}
          setScrollRef={setScrollRef}
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
              isOnline={isOnline}
              conversation={conversation}
            />
          </Box>
        )}
      </Flex>
    </>
  );
};

export default ConversationContainer;
