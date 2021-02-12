import React from 'react';
import {Box} from 'theme-ui';
import {Text} from '../common';
import ConversationItem from './ConversationItem';
import ConversationClosing from './ConversationClosing';
import {getColorByUuid} from './support';
import {useConversations} from './ConversationsProvider';

const ConversationsPreviewList = ({
  loading,
  selectedConversationId,
  conversationIds,
  isConversationClosing,
  onSelectConversation,
}: {
  loading: boolean;
  selectedConversationId: string | null;
  conversationIds: Array<string>;
  isConversationClosing: (conversationId: string) => boolean;
  onSelectConversation: (conversationId: string | null) => any;
}) => {
  const {
    conversationsById,
    messagesByConversation,
    isCustomerOnline,
  } = useConversations();

  return (
    <Box>
      {!loading && conversationIds.length ? (
        conversationIds.map((conversationId) => {
          const conversation = conversationsById[conversationId];
          // TODO: we only care about the most recent message?
          const messages = messagesByConversation[conversationId];
          const {customer_id: customerId} = conversation;
          const isOnline = isCustomerOnline(customerId);
          const isHighlighted = conversationId === selectedConversationId;
          const isClosing = isConversationClosing(conversationId);
          const color = getColorByUuid(customerId);

          if (isClosing) {
            return (
              <ConversationClosing
                key={conversationId}
                isHighlighted={isHighlighted}
              />
            );
          }

          return (
            <ConversationItem
              key={conversationId}
              conversation={conversation}
              messages={messages}
              isHighlighted={isHighlighted}
              isCustomerOnline={isOnline}
              color={color}
              onSelectConversation={onSelectConversation}
            />
          );
        })
      ) : (
        <Box p={3}>
          <Text type="secondary">
            {loading ? 'Loading...' : 'No conversations'}
          </Text>
        </Box>
      )}
    </Box>
  );
};

export default ConversationsPreviewList;
