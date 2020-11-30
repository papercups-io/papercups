import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Badge, Text} from '../common';
import {SmileTwoTone, StarFilled} from '../icons';
import {UserOutlined} from '../icons';

import {formatRelativeTime} from '../../utils';
import {formatRelativeTimeShort} from '../../utils';
import {Conversation, Message} from '../../types';
import {SenderAvatar} from './ChatMessage';
import {getSenderIdentifier} from './ChatMessage';

dayjs.extend(utc);

const formatConversation = (
  conversation: Conversation,
  messages: Array<Message> = []
) => {
  const recent = messages[messages.length - 1];
  console.log(recent);
  const ts = recent ? recent.created_at : conversation.created_at;
  const created = dayjs.utc(ts);
  const date = formatRelativeTimeShort(created);

  return {
    ...conversation,
    user: recent && recent.user ? recent.user: null,
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
  const formatted = formatConversation(conversation, messages);
  const {id, priority, status, customer, user, date, preview, read} = formatted;
  const isAgent = !!user;
  const {name, email} = customer;
  const isPriority = priority === 'priority';
  const isClosed = status === 'closed';
  const tooltip = getSenderIdentifier(customer, user);

  return (
    <Box
      sx={{
        padding: isHighlighted ? '16px 16px 16px 14px' : `${3}`,
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
          <Flex
            mr={2}
            sx={{
              bg:  color,
              height: 32,
              width: 32,
              borderRadius: '50%',
              justifyContent: 'center',
              alignItems: 'center',
              color: '#fff',
            }}
          >
            {isPriority ? (
              <StarFilled style={{fontSize: 16, color: colors.gold}} />
            ) : (
              <UserOutlined style={{color: colors.white}} />
            )}
          </Flex>
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

        {read ? (
          isCustomerOnline ? (
            <Badge status="success" text="Online" />
          ) : (
            <Text type="secondary">{date}</Text>
          )
        ) : (
          <Badge status="processing" />
        )}
      </Flex>
      <Flex sx={{alignItems: 'center'}}>
        {isAgent ? (
          <SenderAvatar name={tooltip} user={user} isAgent={isAgent} color={color} size={16} />
        ) : (
          ''
        )}
        <Box
          style={{
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
          }}
        >
          {read ? (
            <Text type="secondary">{preview}</Text>
          ) : (
            <Text strong>{preview}</Text>
          )}
        </Box>


      </Flex>
    </Box>
  );
};

export default ConversationItem;
