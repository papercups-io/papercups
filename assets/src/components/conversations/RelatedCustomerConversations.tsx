import React from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {colors, Text} from '../common';
import Spinner from '../Spinner';
import {SenderAvatar} from './ChatMessage';
import {
  getColorByUuid,
  getSenderIdentifier,
  getSenderProfilePhoto,
  isAgentMessage,
} from './support';
import * as API from '../../api';
import {Account, Conversation} from '../../types';
import {formatShortRelativeTime} from '../../utils';
import logger from '../../logger';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const RelatedConversationItem = ({
  conversation,
  account,
}: {
  conversation: Conversation;
  account: Account;
}) => {
  const {id, status, created_at, messages = []} = conversation;

  if (!messages || messages.length === 0) {
    return null;
  }

  const [recent] = messages;
  const ts = recent ? recent.created_at : created_at;
  const created = dayjs.utc(ts);
  const date = formatShortRelativeTime(created);
  const {customer_id: customerId} = recent;
  const name = getSenderIdentifier(recent, account);
  const profilePhotoUrl = getSenderProfilePhoto(recent, account);
  const isAgent = isAgentMessage(recent);
  const preview = recent.body ? recent.body : '...';
  const color = customerId ? getColorByUuid(customerId) : colors.gray[0];
  const isOpen = status === 'open';
  const url = isOpen
    ? `/conversations/all/${id}`
    : `/conversations/closed/${id}`;

  return (
    <a key={id} className="RelatedCustomerConversation--link" href={url}>
      <Box
        p={2}
        sx={{
          borderTop: '1px solid #f0f0f0',
        }}
      >
        <Flex
          mb={1}
          sx={{alignItems: 'center', justifyContent: 'space-between'}}
        >
          <SenderAvatar
            isAgent={isAgent}
            color={color}
            size={20}
            name={name}
            avatarPhotoUrl={profilePhotoUrl}
          />
          <Text type="secondary" style={{fontSize: 12}}>
            {date}
          </Text>
        </Flex>
        <Box
          sx={{
            maxWidth: '100%',
            overflow: 'hidden',
            whiteSpace: 'nowrap',
            textOverflow: 'ellipsis',
          }}
        >
          <Text type="secondary">{preview}</Text>
        </Box>
      </Box>
    </a>
  );
};

const RelatedCustomerConversations = ({
  conversationId,
}: {
  conversationId: string;
}) => {
  const [loading, setLoading] = React.useState(false);
  const [account, setAccount] = React.useState<Account | null>(null);
  const [conversations, setRelatedConversations] = React.useState<
    Array<Conversation>
  >([]);

  React.useEffect(() => {
    setLoading(true);

    Promise.all([
      API.fetchAccountInfo(),
      API.fetchRelatedConversations(conversationId),
    ])
      .then(([account, conversations]) => {
        setAccount(account);
        setRelatedConversations(conversations);
      })
      .catch((err) =>
        logger.error('Error retrieving related conversations:', err)
      )
      .then(() => setLoading(false));
  }, [conversationId]);

  const conversationsWithMessages = conversations.filter((conversation) => {
    const {messages = []} = conversation;

    return messages && messages.length > 0;
  });

  if (loading || !account) {
    return <Spinner size={16} />;
  } else if (conversationsWithMessages.length === 0) {
    return (
      <Box mx={2} mb={2}>
        <Text type="secondary">None</Text>
      </Box>
    );
  }

  return (
    <Box>
      {conversationsWithMessages.map((conversation) => {
        return (
          <RelatedConversationItem
            key={conversation.id}
            account={account}
            conversation={conversation}
          />
        );
      })}
    </Box>
  );
};

export default RelatedCustomerConversations;
