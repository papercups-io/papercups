import React from 'react';
import {Box, Flex, SxStyleProp} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text, Tooltip} from '../common';
import {UserOutlined} from '../icons';
import {formatRelativeTime} from '../../utils';
import {Account, Message} from '../../types';
import {
  getColorByUuid,
  getSenderIdentifier,
  getSenderProfilePhoto,
  isAgentMessage,
} from './support';
import ChatMessageBox from './ChatMessageBox';

dayjs.extend(utc);

export const SenderAvatar = ({
  isAgent,
  name,
  avatarPhotoUrl,
  size = 32,
  color = colors.gold,
  sx = {},
}: {
  isAgent: boolean;
  name: string;
  avatarPhotoUrl?: string | null;
  size?: number;
  color?: string;
  sx?: SxStyleProp;
}) => {
  if (avatarPhotoUrl) {
    return (
      <Tooltip title={name}>
        <Box
          sx={{
            mr: 2,
            height: size,
            width: size,
            borderRadius: '50%',
            justifyContent: 'center',
            alignItems: 'center',

            backgroundPosition: 'center',
            backgroundSize: 'cover',
            backgroundImage: `url(${avatarPhotoUrl})`,

            ...sx,
          }}
        />
      </Tooltip>
    );
  }

  return (
    <Tooltip title={name}>
      <Flex
        sx={{
          mr: 2,
          bg: isAgent ? colors.primary : color,
          height: size,
          width: size,
          fontSize: size < 24 ? 12 : 'inherit',
          borderRadius: '50%',
          justifyContent: 'center',
          alignItems: 'center',
          color: '#fff',
          ...sx,
        }}
      >
        {isAgent ? (
          name.slice(0, 1).toUpperCase()
        ) : (
          <UserOutlined
            style={{color: colors.white, fontSize: size < 24 ? 12 : 'inherit'}}
          />
        )}
      </Flex>
    </Tooltip>
  );
};

type Props = {
  message: Message;
  account?: Account | null;
  isMe?: boolean;
  isLastInGroup?: boolean;
  shouldDisplayTimestamp?: boolean;
};

const ChatMessage = ({
  message,
  account,
  isMe,
  isLastInGroup,
  shouldDisplayTimestamp,
}: Props) => {
  const {
    sent_at,
    created_at,
    seen_at,
    customer_id: customerId,
    private: isPrivate,
    attachments = [],
  } = message;
  const isAgent = isAgentMessage(message);
  const sentAt = dayjs.utc(sent_at || created_at);
  const formattedSentAt = formatRelativeTime(sentAt);
  const seenAt = seen_at ? dayjs.utc(seen_at) : null;
  const formattedSeenAt = seenAt ? formatRelativeTime(seenAt) : null;
  const tooltip = getSenderIdentifier(message, account);
  const color = getColorByUuid(customerId);
  const avatarPhotoUrl = getSenderProfilePhoto(message, account);

  if (isMe) {
    return (
      <Box pr={0} pl={4} pb={isLastInGroup ? 3 : 2}>
        <Flex sx={{justifyContent: 'flex-end', alignItems: 'flex-end'}}>
          <ChatMessageBox
            className={isPrivate ? '' : 'Text--white'}
            message={message}
            sx={{
              background: isPrivate ? colors.note : colors.primary,
              maxWidth: '80%',
            }}
            attachmentTextColor={isPrivate ? colors.text : colors.white}
            attachments={attachments}
          />
        </Flex>
        {shouldDisplayTimestamp && (
          <Flex m={1} sx={{justifyContent: 'flex-end'}}>
            {formattedSeenAt ? (
              <Text type="secondary">Seen {formattedSeenAt}</Text>
            ) : (
              <Text type="secondary">Sent {formattedSentAt}</Text>
            )}
          </Flex>
        )}
      </Box>
    );
  }

  return (
    <Box pr={4} pl={0} pb={isLastInGroup ? 3 : 2}>
      <Flex sx={{justifyContent: 'flex-start', alignItems: 'flex-end'}}>
        {isLastInGroup ? (
          <SenderAvatar
            sx={{mb: '2px'}}
            name={tooltip}
            avatarPhotoUrl={avatarPhotoUrl}
            isAgent={isAgent}
            color={color}
          />
        ) : (
          <Box
            mr={2}
            style={{
              height: 32,
              width: 32,
              borderRadius: '50%',
              justifyContent: 'center',
              alignItems: 'center',
            }}
          />
        )}
        <ChatMessageBox
          message={message}
          sx={{
            background: isPrivate ? colors.note : 'rgb(245, 245, 245)',
            maxWidth: '80%',
          }}
          attachments={attachments}
        />
      </Flex>
      {shouldDisplayTimestamp && (
        <Flex my={1} mx={2} pl={4} sx={{justifyContent: 'flex-start'}}>
          <Text type="secondary">Sent {formattedSentAt}</Text>
        </Flex>
      )}
    </Box>
  );
};

export default ChatMessage;
