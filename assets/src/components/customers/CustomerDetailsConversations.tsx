import React, {useEffect, useMemo, useState} from 'react';
import {useHistory} from 'react-router-dom';
import {Flex} from 'theme-ui';
import {Empty} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import {Conversation} from '../../types';
import {getColorByUuid} from '../conversations/support';
import ConversationItem from '../conversations/ConversationItem';
import StartConversationButton from '../conversations/StartConversationButton';
import {sortConversationMessages} from '../../utils';

type Props = {customerId: string};

const CustomerDetailsConversations = ({customerId}: Props) => {
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const history = useHistory();

  const hasOpenConversation = useMemo(() => {
    const openConversation = conversations.find(
      (conversation) => conversation.status === 'open'
    );

    return !!openConversation;
  }, [conversations]);

  const fetchConversations = async () => {
    setIsLoading(true);

    const {data: conversations} = await API.fetchConversations({
      customer_id: customerId,
    });

    setConversations(conversations);
    setIsLoading(false);
  };

  const handleSelectConversation = (conversationId: string) => {
    const conversation = conversations.find(
      (conversation) => conversation.id === conversationId
    );
    const isClosed = conversation && conversation.status === 'closed';
    const url = isClosed
      ? `/conversations/closed?cid=${conversationId}`
      : `/conversations/all?cid=${conversationId}`;

    history.push(url);
  };

  useEffect(() => {
    fetchConversations();
  }, [customerId]);

  if (isLoading) {
    return (
      <Flex
        p={4}
        sx={{
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center',
          height: '100%',
        }}
      >
        <Spinner size={40} />
      </Flex>
    );
  }

  return (
    <>
      <Flex
        p={3}
        sx={{
          justifyContent: 'flex-end',
        }}
      >
        <StartConversationButton
          customerId={customerId}
          isDisabled={hasOpenConversation}
          onInitializeNewConversation={fetchConversations}
        />
      </Flex>

      {conversations.length > 0 ? (
        conversations.map((conversation) => {
          const {
            id: conversationId,
            customer_id: customerId,
            messages = [],
          } = conversation;
          const color = getColorByUuid(customerId);
          const sorted = sortConversationMessages(messages);

          return (
            <ConversationItem
              key={conversationId}
              conversation={conversation}
              messages={sorted}
              color={color}
              onSelectConversation={handleSelectConversation}
            />
          );
        })
      ) : (
        <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} />
      )}
    </>
  );
};

export default CustomerDetailsConversations;
