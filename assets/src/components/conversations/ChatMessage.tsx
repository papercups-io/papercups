import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text} from '../common';
import {SmileTwoTone} from '../icons';
import {formatRelativeTime} from '../../utils';
import {Message} from '../../types';

dayjs.extend(utc);

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
  const {body, created_at, user_id} = message;
  const isAgent = !!user_id;
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
            <Text type="secondary">Sent {timestamp}</Text>
          </Flex>
        )}
      </Box>
    );
  }

  return (
    <Box pr={4} pl={0} pb={isLastInGroup ? 3 : 2}>
      <Flex sx={{justifyContent: 'flex-start', alignItems: 'center'}}>
        <Box mr={3} mt={1}>
          {/* TODO: include name/email to distinguish between agents */}
          <SmileTwoTone
            style={{fontSize: 20}}
            twoToneColor={isAgent ? colors.primary : colors.gold}
          />
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
          <Text type="secondary">Sent {timestamp}</Text>
        </Flex>
      )}
    </Box>
  );
};

export default ChatMessage;
