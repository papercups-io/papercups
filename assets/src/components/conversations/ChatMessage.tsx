import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text, Tooltip} from '../common';
import {UserOutlined} from '../icons';
import {formatRelativeTime} from '../../utils';
import {Customer, Message, User} from '../../types';
import {getColorByUuid} from './support';
import ChatMessageBox from './ChatMessageBox';

dayjs.extend(utc);

const getSenderIdentifier = (customer?: Customer | null, user?: User) => {
  if (user) {
    const {display_name, full_name, email} = user;

    return display_name || full_name || email || 'Agent';
  } else if (customer) {
    const {name, email} = customer;

    return name || email || 'Anonymous User';
  } else {
    return 'Anonymous User';
  }
};

const SenderAvatar = ({
  isAgent,
  name,
  user,
  color = colors.gold,
}: {
  isAgent: boolean;
  name: string;
  user?: User;
  color?: string;
}) => {
  const profilePhotoUrl = user && user.profile_photo_url;

  if (profilePhotoUrl) {
    return (
      <Tooltip title={name}>
        <Box
          mr={2}
          style={{
            height: 32,
            width: 32,
            borderRadius: '50%',
            justifyContent: 'center',
            alignItems: 'center',

            backgroundPosition: 'center',
            backgroundSize: 'cover',
            backgroundImage: `url(${profilePhotoUrl})`,
          }}
        />
      </Tooltip>
    );
  }

  return (
    <Tooltip title={name}>
      <Flex
        mr={2}
        sx={{
          bg: isAgent ? colors.primary : color,
          height: 32,
          width: 32,
          borderRadius: '50%',
          justifyContent: 'center',
          alignItems: 'center',
          color: '#fff',
        }}
      >
        {isAgent ? (
          name.slice(0, 1).toUpperCase()
        ) : (
          <UserOutlined style={{color: colors.white}} />
        )}
      </Flex>
    </Tooltip>
  );
};

type Props = {
  message: Message;
  customer?: Customer | null;
  isMe?: boolean;
  isLastInGroup?: boolean;
  shouldDisplayTimestamp?: boolean;
};

const ChatMessage = ({
  message,
  customer,
  isMe,
  isLastInGroup,
  shouldDisplayTimestamp,
}: Props) => {
  const {body, sent_at, created_at, user, seen_at} = message;
  const isAgent = !!user;
  const tooltip = getSenderIdentifier(customer, user);
  const sentAt = dayjs.utc(sent_at || created_at);
  const formattedSentAt = formatRelativeTime(sentAt);
  const seenAt = seen_at ? dayjs.utc(seen_at) : null;
  const formattedSeenAt = seenAt ? formatRelativeTime(seenAt) : null;
  const customerId = customer && customer.id;
  const color = getColorByUuid(customerId);

  if (isMe) {
    return (
      <Box pr={0} pl={4} pb={isLastInGroup ? 3 : 2}>
        <Flex sx={{justifyContent: 'flex-end'}}>
          <ChatMessageBox
            className="Text--white"
            content={body}
            sx={{
              px: 3,
              py: 2,
              background: colors.primary,
            }}
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
      <Flex sx={{justifyContent: 'flex-start', alignItems: 'center'}}>
        <SenderAvatar
          name={tooltip}
          user={user}
          isAgent={isAgent}
          color={color}
        />
        <ChatMessageBox
          content={body}
          sx={{
            px: 3,
            py: 2,
            background: 'rgb(245, 245, 245)',
            maxWidth: '80%',
          }}
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
