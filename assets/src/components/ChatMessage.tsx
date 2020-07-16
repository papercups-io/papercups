import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text} from './common';
import {SmileTwoTone} from './icons';
import {formatRelativeTime} from '../utils';

dayjs.extend(utc);

// TODO: DRY up
type Message = {
  sender: string;
  body: string;
  created_at: string;
  customer_id: string;
};

type Props = {
  message: Message;
  isMe?: boolean;
  isLastInGroup?: boolean;
  shouldDisplayTimestamp?: boolean;
};

const ChatMessage = ({
  message,
  isMe,
  isLastInGroup,
  shouldDisplayTimestamp,
}: Props) => {
  const {body, created_at} = message;
  const created = dayjs.utc(created_at);
  const timestamp = formatRelativeTime(created);

  if (isMe) {
    return (
      <Box pr={0} pl={4} pb={isLastInGroup ? 3 : 2}>
        <Flex sx={{justifyContent: 'flex-end'}}>
          <Box
            px={3}
            py={2}
            sx={{
              color: colors.white,
              background: colors.primary,
              borderRadius: 4,
            }}
          >
            {body}
          </Box>
        </Flex>
        {shouldDisplayTimestamp && (
          <Flex m={1} sx={{justifyContent: 'flex-end'}}>
            {/* TODO: this should be dynamic */}
            <Text type="secondary">Sent {timestamp || '30 mins ago'}</Text>
          </Flex>
        )}
      </Box>
    );
  }

  return (
    <Box pr={4} pl={0} pb={isLastInGroup ? 3 : 2}>
      <Flex sx={{justifyContent: 'flex-start', alignItems: 'center'}}>
        <Box mr={3} mt={1}>
          <SmileTwoTone style={{fontSize: 20}} twoToneColor={colors.gold} />
        </Box>
        <Box
          px={3}
          py={2}
          sx={{
            color: colors.black,
            background: 'rgb(245, 245, 245)',
            borderRadius: 4,
            maxWidth: '80%',
          }}
        >
          {body}
        </Box>
      </Flex>
      {shouldDisplayTimestamp && (
        <Flex m={1} pl={4} sx={{justifyContent: 'flex-start'}}>
          {/* TODO: this should be dynamic */}
          <Text type="secondary">Sent {timestamp || '30 mins ago'}</Text>
        </Flex>
      )}
    </Box>
  );
};

export default ChatMessage;
