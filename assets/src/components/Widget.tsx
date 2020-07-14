import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Socket, Channel} from 'phoenix';
import {colors, Button, TextArea, Title} from './common';
import {SendOutlined} from './icons';
import ChatMessage from './ChatMessage';
import * as API from '../api';
import {getCustomerId, setCustomerId} from '../storage';

// const socket = new Socket('ws://localhost:4000/socket');
const socket = new Socket('/socket');

// TODO:
type Message = {
  sender: string;
  body: string;
  created_at: string;
  customer_id: string;
};

type Props = {};
type State = {
  message: string;
  messages: Array<Message>;
  customerId: string;
  accountId: string;
  conversationId: string | null;
};

class Widget extends React.Component<Props, State> {
  scrollToEl: any = null;

  channel: Channel | null = null;

  state: State = {
    message: '',
    messages: [],
    // TODO: figure out how to determine these, either by IP or localStorage
    // (eventually we will probably use cookies for this)
    customerId: getCustomerId(),
    // TODO: maybe pass in as prop for now?
    accountId: 'eb504736-0f20-4978-98ff-1a82ae60b266',
    conversationId: null,
  };

  componentDidMount() {
    socket.connect();

    this.fetchLatestConversation(this.state.customerId);
  }

  fetchLatestConversation = (customerId: string) => {
    const {accountId} = this.state;

    console.log('Fetching conversations for customer:', customerId);

    if (!customerId) {
      return this.initializeNewConversation();
    }

    API.fetchCustomerConversations(customerId, accountId)
      .then((conversations) => {
        console.log('Found existing conversations:', conversations);

        if (!conversations || !conversations.length) {
          return this.initializeNewConversation();
        }

        const [latest] = conversations;
        const {id: conversationId, messages = []} = latest;

        this.setState({
          conversationId,
          messages: messages
            .map((msg: any) => {
              return {
                body: msg.body,
                created_at: msg.created_at,
                customer_id: msg.customer_id,
                // Deprecate
                sender: msg.customer_id ? 'customer' : 'agent',
              };
            })
            .sort(
              (a: any, b: any) =>
                +new Date(a.created_at) - +new Date(b.created_at)
            ),
        });

        this.joinConversationChannel(conversationId);
      })
      .catch((err) => console.log('Error fetching conversations!', err));
  };

  createNewCustomerId = async (accountId: string) => {
    const {id: customerId} = await API.createNewCustomer(accountId);

    setCustomerId(customerId);

    return customerId;
  };

  initializeNewConversation = async () => {
    const {accountId} = this.state;

    const customerId = await this.createNewCustomerId(accountId);
    const {id: conversationId} = await API.createNewConversation(
      accountId,
      customerId
    );

    this.setState({customerId, conversationId, messages: []});

    this.joinConversationChannel(conversationId);
  };

  joinConversationChannel = (conversationId: string) => {
    if (this.channel && this.channel.leave) {
      this.channel.leave(); // TODO: what's the best practice here?
    }

    console.log('Joining channel:', conversationId);

    this.channel = socket.channel(`conversation:${conversationId}`, {});

    this.channel.on('shout', (message) => {
      this.handleNewMessage(message);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        console.log('Joined successfully!', res);
      })
      .receive('error', (err) => {
        console.log('Unable to join!', err);
      });

    this.scrollToEl.scrollIntoView();
  };

  handleNewMessage = (message: Message) => {
    this.setState({messages: [...this.state.messages, message]}, () => {
      this.scrollToEl.scrollIntoView();
    });
  };

  handleMessageChange = (e: any) => {
    this.setState({message: e.target.value});
  };

  handleKeyDown = (e: any) => {
    if (e.key === 'Enter') {
      this.handleSendMessage(e);
    }
  };

  handleSendMessage = (e?: any) => {
    e && e.preventDefault();

    const {message, customerId, accountId, conversationId} = this.state;

    if (!this.channel || !message || message.trim().length === 0) {
      return;
    }

    this.channel.push('shout', {
      body: message,
      sender: 'customer',
      // created_at: new Date(),
      conversation_id: conversationId,
      account_id: accountId,
      customer_id: customerId,
    });

    this.setState({message: ''});
  };

  render() {
    const {customerId, message, messages = []} = this.state;

    return (
      <Flex
        sx={{
          background: colors.white,
          flexDirection: 'column',
          height: '100%',
          width: '100%',
        }}
      >
        <Box
          p={4}
          sx={{
            background: colors.primary,
          }}
        >
          <Title level={4} style={{color: colors.white, margin: 0}}>
            Welcome to Taro!
          </Title>
        </Box>
        <Box
          p={3}
          sx={{
            flex: 1,
            boxShadow: 'rgba(0, 0, 0, 0.2) 0px 21px 4px -20px inset',
            overflowY: 'scroll',
          }}
        >
          {messages.map((msg, key) => {
            // Slight hack
            const next = messages[key + 1];
            const isLastInGroup = next
              ? msg.customer_id !== next.customer_id
              : true;
            const shouldDisplayTimestamp = key === messages.length - 1;

            return (
              <ChatMessage
                key={key}
                message={msg}
                isMe={msg.customer_id === customerId}
                isLastInGroup={isLastInGroup}
                shouldDisplayTimestamp={shouldDisplayTimestamp}
              />
            );
          })}
          <div ref={(el) => (this.scrollToEl = el)} />
        </Box>
        <Box
          p={3}
          sx={{
            borderTop: '1px solid rgb(230, 230, 230)',
            // TODO: only show shadow on focus TextArea below
            boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 100px 0px',
          }}
        >
          <Flex sx={{alignItems: 'center'}}>
            <Box mr={3} sx={{flex: 1}}>
              <TextArea
                className="TextArea--transparent"
                autoSize={{minRows: 1, maxRows: 4}}
                autoFocus
                value={message}
                onKeyDown={this.handleKeyDown}
                onChange={this.handleMessageChange}
              />
            </Box>
            <Box px={3}>
              <Button
                htmlType="submit"
                type="primary"
                shape="circle"
                icon={<SendOutlined />}
                onClick={this.handleSendMessage}
              />
            </Box>
          </Flex>
        </Box>
      </Flex>
    );
  }
}

export default Widget;
