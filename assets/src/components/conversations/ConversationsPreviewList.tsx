import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Text} from '../common';
import ConversationItem from './ConversationItem';
import ConversationClosing from './ConversationClosing';
import {getColorByUuid} from './support';
import {useConversations} from './ConversationsProvider';
import {Conversation} from '../../types';

const ConversationsPreviewList = ({
  loading,
  selectedConversationId,
  conversationIds = [],
  hasMoreConversations,
  isConversationClosing,
  onSelectConversation,
  onLoadMoreConversations,
}: {
  loading: boolean;
  selectedConversationId: string | null;
  conversationIds: Array<string>;
  hasMoreConversations?: boolean;
  isConversationClosing: (conversationId: string) => boolean;
  onSelectConversation: (conversationId: string | null) => any;
  onLoadMoreConversations: () => void;
}) => {
  const {
    conversationsById,
    messagesByConversation,
    isCustomerOnline,
  } = useConversations();

  const conversations = conversationIds
    .map((conversationId) => conversationsById[conversationId])
    .sort((a: Conversation, b: Conversation) => {
      const left = a.last_activity_at
        ? +new Date(a.last_activity_at)
        : -Infinity;
      const right = b.last_activity_at
        ? +new Date(b.last_activity_at)
        : -Infinity;

      return right - left;
    });

  return (
    <Box>
      {!loading && conversationIds.length ? (
        conversations.map((conversation) => {
          const {id: conversationId, customer_id: customerId} = conversation;
          // TODO: we only care about the most recent message?
          const messages = messagesByConversation[conversationId];
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

      {!loading && conversationIds.length > 0 && !!hasMoreConversations && (
        <Flex p={2} sx={{justifyContent: 'center'}}>
          <Button
            type="text"
            style={{width: '100%'}}
            onClick={onLoadMoreConversations}
          >
            Load more...
          </Button>
        </Flex>
      )}
    </Box>
  );
};

export default ConversationsPreviewList;
