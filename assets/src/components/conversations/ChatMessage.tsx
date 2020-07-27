import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text, Tooltip} from '../common';
import {UserOutlined} from '../icons';
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
  const {body, created_at, user} = message;
  const isAgent = !!user;
  // TODO: once we have customer metadata, show customer name/email here instead
  const tooltip = user ? user.email : 'Anonymous Customer';
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
        <Tooltip title={tooltip}>
          <Flex
            mr={2}
            sx={{
              bg: isAgent ? colors.primary : colors.gold,
              height: 32,
              width: 32,
              borderRadius: '50%',
              justifyContent: 'center',
              alignItems: 'center',
              color: '#fff',
            }}
          >
            {isAgent ? (
              tooltip.slice(0, 1).toUpperCase()
            ) : (
              <UserOutlined style={{color: colors.white}} />
            )}
          </Flex>
        </Tooltip>

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
        <Flex my={1} mx={2} pl={4} sx={{justifyContent: 'flex-start'}}>
          <Text type="secondary">Sent {timestamp}</Text>
        </Flex>
      )}
    </Box>
  );
};

export default ChatMessage;
