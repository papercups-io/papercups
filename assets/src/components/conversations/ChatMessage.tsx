import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {colors, Text, Tooltip} from '../common';
import {UserOutlined} from '../icons';
import {formatRelativeTime} from '../../utils';
import {Customer, Message, User} from '../../types';

dayjs.extend(utc);

const getSenderIdentifier = (customer?: Customer, user?: User) => {
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
}: {
  isAgent: boolean;
  name: string;
  user?: User;
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
  customer?: Customer;
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
  const {body, created_at, user} = message;
  const isAgent = !!user;
  const tooltip = getSenderIdentifier(customer, user);
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
        <SenderAvatar name={tooltip} user={user} isAgent={isAgent} />

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
