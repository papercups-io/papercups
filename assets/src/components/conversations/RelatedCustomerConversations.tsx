import React from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {colors, Text} from '../common';
import Spinner from '../Spinner';
import {getSenderIdentifier, SenderAvatar} from './ChatMessage';
import {getColorByUuid} from './support';
import * as API from '../../api';
import {Conversation} from '../../types';
import {formatShortRelativeTime} from '../../utils';
import logger from '../../logger';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const RelatedConversationItem = ({
  conversation,
}: {
  conversation: Conversation;
}) => {
  const {id, status, created_at, messages = []} = conversation;
  const [recent] = messages;
  const ts = recent ? recent.created_at : created_at;
  const created = dayjs.utc(ts);
  const date = formatShortRelativeTime(created);
  const {user, customer} = recent;
  const name = getSenderIdentifier(customer, user);
  const isAgent = !!user;
  const preview = recent.body ? recent.body : '...';
  const customerId = customer && customer.id;
  const color = customerId ? getColorByUuid(customerId) : colors.gray[0];
  const isOpen = status === 'open';
  const url = isOpen
    ? `/conversations/all?cid=${id}`
    : `/conversations/closed?cid=${id}`;

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
            user={user}
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
  const [conversations, setRelatedConversations] = React.useState<
    Array<Conversation>
  >([]);

  React.useEffect(() => {
    setLoading(true);

    API.fetchRelatedConversations(conversationId)
      .then((results) => setRelatedConversations(results))
      .catch((err) =>
        logger.error('Error retrieving related conversations:', err)
      )
      .then(() => setLoading(false));
  }, [conversationId]);

  if (loading) {
    return <Spinner size={16} />;
  } else if (!conversations || !conversations.length) {
    return (
      <Box mx={2} mb={2}>
        <Text type="secondary">None</Text>
      </Box>
    );
  }

  return (
    <Box>
      {conversations.map((conversation) => {
        return (
          <RelatedConversationItem
            key={conversation.id}
            conversation={conversation}
          />
        );
      })}
    </Box>
  );
};

export default RelatedCustomerConversations;
