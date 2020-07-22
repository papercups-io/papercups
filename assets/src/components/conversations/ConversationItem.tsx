import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text} from '../common';
import {SmileTwoTone, StarFilled} from '../icons';
import {formatRelativeTime} from '../../utils';

dayjs.extend(utc);

// TODO: add types!
const formatConversation = (conversation: any, messages: Array<any> = []) => {
  const recent = messages[messages.length - 1];
  const ts = recent ? recent.created_at : conversation.created_at;
  const created = dayjs.utc(ts);
  const date = formatRelativeTime(created);

  return {
    ...conversation,
    customer: 'Anonymous User',
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
  onSelectConversation,
}: {
  conversation: Array<any>;
  messages: Array<any>;
  color: string;
  isHighlighted?: boolean;
  onSelectConversation: (id: string) => void;
}) => {
  const formatted = formatConversation(conversation, messages);
  const {id, priority, status, customer, date, preview, read} = formatted;
  const isPriority = priority === 'priority';
  const isClosed = status === 'closed';

  return (
    <Box
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
          <Text strong>{customer}</Text>
        </Flex>
        <Text type="secondary">{date}</Text>
      </Flex>
      <Box
        style={{
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}
      >
        <Text strong={!read}>{preview}</Text>
      </Box>
    </Box>
  );
};

export default ConversationItem;
