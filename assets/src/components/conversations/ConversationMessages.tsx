import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Divider, Result} from '../common';
import {SmileOutlined, UpOutlined} from '../icons';
import Spinner from '../Spinner';
import ChatMessage from './ChatMessage';
import {Account, Conversation, Message, User} from '../../types';
import {sortConversationMessages} from '../../utils';
import {isBotMessage} from './support';

const noop = () => {};

const EmptyMessagesPlaceholder = () => {
  return (
    <Box my={4}>
      <Result
        status="success"
        title="No messages"
        subTitle="Nothing to show here! Take a well-earned break 😊"
      />
    </Box>
  );
};

const GettingStartedRedirect = () => {
  return (
    <Box my={4}>
      <Result
        icon={<SmileOutlined />}
        title="No messages"
        subTitle="It looks like your widget hasn't been set up yet!"
        extra={
          <Link to="/settings/chat-widget">
            <Button type="primary">Get Started</Button>
          </Link>
        }
      />
    </Box>
  );
};

const ConversationMessages = ({
  conversationId,
  messages,
  account,
  currentUser,
  loading,
  isClosing,
  showGetStarted,
  isLoadingPreviousConversation,
  hasPreviousConversations,
  history = [],
  sx = {},
  setScrollRef,
  isCurrentUserMessage,
  onLoadPreviousConversation = noop,
}: {
  conversationId?: string | null;
  messages: Array<Message>;
  account?: Account | null;
  currentUser?: User | null;
  loading?: boolean;
  isClosing?: boolean;
  showGetStarted?: boolean;
  isLoadingPreviousConversation?: boolean;
  hasPreviousConversations?: boolean;
  history?: Array<Conversation>;
  sx?: any;
  setScrollRef: (el: any) => void;
  isCurrentUserMessage?: (message: Message) => boolean;
  onLoadPreviousConversation?: (conversationId: string) => void;
}) => {
  const [historyRefs, setHistoryRefs] = React.useState<Array<any>>([]);
  // Sets old behavior as default, but eventually we may just want to show
  // any message with a `user_id` (as opposed to `customer_id`) as an agent
  // (Note that this will require an update to the <ChatMessage /> UI component
  // in order to distinguish between different agents by e.g. profile photo)
  const isCurrentUserMessageDefaultFn = (message: Message) => {
    const {user_id: userId} = message;

    if (!userId || !currentUser || isBotMessage(message)) {
      return false;
    }

    return userId === currentUser.id;
  };

  const isCurrentUserMsg =
    typeof isCurrentUserMessage === 'function'
      ? isCurrentUserMessage
      : isCurrentUserMessageDefaultFn;

  const addToHistoryRefs = (el: any) => {
    if (el && el.id) {
      const ids = historyRefs.map((el) => el.id);

      if (ids.includes(el.id)) {
        return;
      }

      setHistoryRefs([el, ...historyRefs]);

      // TODO: figure out the best way to handle this scroll behavior...
      // might be nice to add a nice animation when the previous conversation is loaded
      el.scrollIntoView({
        behavior: 'auto',
        block: 'start',
        inline: 'nearest',
      });
    }
  };

  const handleLoadPrevious = () => {
    if (history && history.length) {
      const [{id: earliestConversationId}] = history;

      onLoadPreviousConversation(earliestConversationId);
    } else if (conversationId) {
      onLoadPreviousConversation(conversationId);
    } else {
      // No conversation detected yet; do nothing
    }
  };

  return (
    <Box
      sx={{
        flex: 1,
        overflowY: 'scroll',
        opacity: isClosing ? 0.6 : 1,
      }}
    >
      {loading ? (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      ) : (
        <Box
          backgroundColor={colors.white}
          sx={{minHeight: '100%', p: 4, ...sx}}
        >
          {hasPreviousConversations ? (
            <Flex
              sx={{
                justifyContent: 'center',
                alignItems: 'center',
                position: 'relative',
                top: -16,
              }}
            >
              <Button
                className="Button--faded"
                size="small"
                icon={<UpOutlined />}
                loading={isLoadingPreviousConversation}
                onClick={handleLoadPrevious}
              >
                Load previous conversation
              </Button>
            </Flex>
          ) : (
            <Box pt={1} mb={3} />
          )}

          {history && history.length
            ? history.map((conversation: Conversation) => {
                const {id: conversationId, messages = []} = conversation;

                return (
                  <React.Fragment key={conversationId}>
                    <Box sx={{opacity: 0.6}}>
                      {sortConversationMessages(messages).map(
                        (message: Message, key: number) => {
                          // Slight hack
                          const next = messages[key + 1];
                          const {
                            id: messageId,
                            customer_id: customerId,
                          } = message;
                          const isMe = isCurrentUserMsg(message);
                          const isLastInGroup = next
                            ? customerId !== next.customer_id
                            : true;

                          // TODO: fix `isMe` logic for multiple agents
                          return (
                            <ChatMessage
                              key={messageId}
                              account={account}
                              message={message}
                              isMe={isMe}
                              isLastInGroup={isLastInGroup}
                              shouldDisplayTimestamp={isLastInGroup}
                            />
                          );
                        }
                      )}
                    </Box>
                    <div
                      id={`ConversationMessages-history--${conversationId}`}
                      ref={addToHistoryRefs}
                    />
                    <Divider />
                  </React.Fragment>
                );
              })
            : null}

          {messages.length ? (
            messages.map((message: Message, key: number) => {
              // Slight hack
              const next = messages[key + 1];
              const {id: messageId, customer_id: customerId} = message;
              const isMe = isCurrentUserMsg(message);
              const isLastInGroup = next
                ? customerId !== next.customer_id
                : true;

              // TODO: fix `isMe` logic for multiple agents
              return (
                <ChatMessage
                  key={messageId}
                  account={account}
                  message={message}
                  isMe={isMe}
                  isLastInGroup={isLastInGroup}
                  shouldDisplayTimestamp={isLastInGroup}
                />
              );
            })
          ) : showGetStarted ? (
            <GettingStartedRedirect />
          ) : (
            <EmptyMessagesPlaceholder />
          )}
          <div ref={setScrollRef} />
        </Box>
      )}
    </Box>
  );
};

export default ConversationMessages;
