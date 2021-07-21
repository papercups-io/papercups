import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Badge, Text} from '../common';
import {SmileTwoTone, StarFilled} from '../icons';
import {formatRelativeTime} from '../../utils';
import {Conversation, Message} from '../../types';
import {useConversations} from './ConversationsProvider';
import {isUnreadConversation} from './support';

dayjs.extend(utc);

const formatConversation = (
  conversation: Conversation,
  messages: Array<Message> = []
) => {
  const recent = messages[messages.length - 1];
  const ts = recent ? recent.created_at : conversation.created_at;
  const created = dayjs.utc(ts);
  const date = formatRelativeTime(created);

  return {
    ...conversation,
    date: date || '1d', // TODO
    preview: recent && recent.body ? recent.body : '...',
    messages: messages,
  };
};

const ConversationItem = ({
  conversation,
  messages,
  color,
  isHighlighted,
  isCustomerOnline,
  onSelectConversation,
}: {
  conversation: Conversation;
  messages: Array<Message>;
  color: string;
  isHighlighted?: boolean;
  isCustomerOnline?: boolean;
  onSelectConversation: (id: string) => void;
}) => {
  const {currentUser} = useConversations();
  const formatted = formatConversation(conversation, messages);
  const {id, priority, status, customer, date, preview} = formatted;
  const {name, email} = customer;
  const isPriority = priority === 'priority';
  const isClosed = status === 'closed';
  const isRead = !isUnreadConversation(conversation, currentUser);

  return (
    <Box
      id={`ConversationItem--${id}`}
      p={3}
      sx={{
        opacity: isClosed ? 0.8 : 1,
        borderBottom: '1px solid #f0f0f0',
        borderLeft: isHighlighted ? `2px solid ${colors.primary}` : null,
        background: isHighlighted ? colors.blue[0] : null,
        cursor: 'pointer',
      }}
      onClick={() => onSelectConversation(id)}
    >
      <Flex mb={2} sx={{justifyContent: 'space-between'}}>
        <Flex sx={{alignItems: 'center'}}>
          <Box mr={2}>
            {isPriority ? (
              <StarFilled style={{fontSize: 16, color: colors.gold}} />
            ) : (
              <SmileTwoTone style={{fontSize: 16}} twoToneColor={color} />
            )}
          </Box>
          <Text
            strong
            style={{
              maxWidth: 120,
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
              overflow: 'hidden',
            }}
          >
            {name || email || 'Anonymous User'}
          </Text>
        </Flex>

        {isRead ? (
          isCustomerOnline ? (
            <Badge status="success" text="Online" />
          ) : (
            <Text type="secondary">{date}</Text>
          )
        ) : (
          <Badge status="processing" />
        )}
      </Flex>
      <Box
        style={{
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}
      >
        {isRead ? (
          <Text type="secondary">{preview}</Text>
        ) : (
          <Text strong>{preview}</Text>
        )}
      </Box>
    </Box>
  );
};

export default ConversationItem;
