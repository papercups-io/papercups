import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Account, Conversation, User} from '../../types';
import * as API from '../../api';
import ConversationMessages from './ConversationMessages';
import ConversationFooter from './ConversationFooter';
import ConversationDetailsSidebar from './ConversationDetailsSidebar';
import logger from '../../logger';
import {useNotifications} from './NotificationsProvider';

const SelectedConversationContainer = ({
  loading,
  account,
  currentUser,
  conversation,
  isClosing,
  setScrollRef,
}: {
  loading: boolean;
  account: Account;
  currentUser: User;
  conversation: Conversation;
  isClosing: boolean;
  // TODO: handle scrolling within this component?
  setScrollRef: any; // (el: any) => void;
}) => {
  const {isCustomerOnline} = useNotifications();
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

  const selectedConversationId = conversation.id;

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

  const {messages = []} = conversation;
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
        setScrollRef={setScrollRef}
        onLoadPreviousConversation={fetchPreviousConversation}
      />

      {conversation && (
        // NB: the `key` forces a rerender so the input can clear
        // any text from the last conversation and trigger autofocus
        <ConversationFooter
          key={selectedConversationId}
          conversationId={selectedConversationId}
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
  );
};

export default SelectedConversationContainer;
