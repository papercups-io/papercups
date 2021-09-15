import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Text} from '../common';
import ConversationItem from './ConversationItem';
import ConversationClosing from './ConversationClosing';
import {getColorByUuid} from './support';
import {Conversation} from '../../types';
import {isScrolledIntoView, sleep} from '../../utils';
import {useNotifications} from './NotificationsProvider';

const ConversationsPreviewList = ({
  loading,
  selectedConversationId,
  conversations = [],
  hasMoreConversations,
  isConversationClosing,
  onSelectConversation,
  onLoadMoreConversations,
}: {
  loading: boolean;
  selectedConversationId: string | null;
  conversations: Array<Conversation>;
  hasMoreConversations?: boolean;
  isConversationClosing: (conversationId: string) => boolean;
  onSelectConversation: (conversationId: string | null) => any;
  onLoadMoreConversations: () => Promise<void>;
}) => {
  const [isFetchingMore, setFetchingMore] = React.useState(false);
  const {isCustomerOnline} = useNotifications();

  React.useEffect(() => {
    if (
      selectedConversationId &&
      conversations.map((c) => c.id).indexOf(selectedConversationId) !== -1
    ) {
      // Scrolls to highlighted ConversationItem component if not visible
      const el = document.getElementById(
        `ConversationItem--${selectedConversationId}`
      );

      if (!isScrolledIntoView(el)) {
        el?.scrollIntoView(false);
      }
    }
    // eslint-disable-next-line
  }, [selectedConversationId]);

  const handleLoadMoreConversations = async () => {
    setFetchingMore(true);

    await sleep(400);
    await onLoadMoreConversations();
    await sleep(400);

    setFetchingMore(false);
  };

  return (
    <Box>
      {!loading && conversations.length ? (
        conversations.map((conversation) => {
          const {
            id: conversationId,
            customer_id: customerId,
            // NB: we only care about the most recent message
            messages = [],
          } = conversation;
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

      {!loading && conversations.length > 0 && !!hasMoreConversations && (
        <Flex p={2} sx={{justifyContent: 'center'}}>
          <Button
            type="text"
            style={{width: '100%'}}
            loading={isFetchingMore}
            onClick={handleLoadMoreConversations}
          >
            Load more...
          </Button>
        </Flex>
      )}
    </Box>
  );
};

export default ConversationsPreviewList;
