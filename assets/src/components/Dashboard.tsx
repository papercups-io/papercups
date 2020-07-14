import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Socket, Channel} from 'phoenix';
import * as API from '../api';
import {
  colors,
  Button,
  Content,
  Footer,
  Layout,
  Sider,
  Text,
  TextArea,
  Title,
} from './common';
import {SmileTwoTone} from './icons';
import ChatMessage from './ChatMessage';

// TODO: don't hardcode this
// const socket = new Socket('ws://localhost:4000/socket');
const socket = new Socket('/socket');

// NB: actual message records will look slightly different
type Message = {
  sender: string;
  body: string;
  created_at: string;
  customer_id: string;
};
// NB: actual conversation records will look different
type Conversation = {
  id: string;
  customer: string;
  date: string;
  preview: string;
  messages?: Array<Message>;
};

type Props = {};
type State = {
  message: string;
  messages: Array<Message>;
  accountId: string;
  userId: string;
  conversations: Array<Conversation>;
  selectedConversationId?: string | null;
};

class Dashboard extends React.Component<Props, State> {
  scrollToEl: any = null;

  channel: Channel | null = null;

  state: State = {
    message: '',
    accountId: 'EB504736-0F20-4978-98FF-1A82AE60B266', // TODO: get from auth provider
    userId: '1', // TODO: get from auth provider
    conversations: [],
    messages: [],
    selectedConversationId: null,
  };

  componentDidMount() {
    socket.connect();

    API.me().then(console.log).catch(console.log);

    // TODO: update API to fetch only conversations by account
    API.fetchConversations()
      .then((conversations) => {
        console.log('Conversations!', conversations);

        if (!conversations || !conversations.length) {
          return; // TODO: handle empty state
        }

        const [first = {} as Conversation] = conversations;
        const {id: selectedConversationId, messages = []} = first;

        this.setState(
          {
            selectedConversationId,
            messages: messages
              .map((msg: any) => {
                return {
                  sender: 'customer',
                  body: msg.body,
                  created_at: msg.created_at,
                  customer_id: msg.customer_id,
                };
              })
              .sort(
                (a: any, b: any) =>
                  +new Date(a.created_at) - +new Date(b.created_at)
              ),
            conversations: conversations.map((conv: any) => {
              const i = Math.floor(Math.random() * 3);
              // const name = ['Alex', 'Kam', 'Emily'][i];
              const name = 'Anonymous User';
              const location = ['New York', 'San Francisco', 'New York'][i];

              const messages = conv.messages.sort(
                (a: any, b: any) =>
                  +new Date(a.created_at) - +new Date(b.created_at)
              );
              const recent = messages[messages.length - 1];

              return {
                id: conv.id,
                customer: `${name}`,
                date: '1d',
                preview: recent && recent.body ? recent.body : '...',
                messages: messages,
              };
            }),
          },
          () => this.scrollToEl.scrollIntoView()
        );

        this.joinConversationChannel(selectedConversationId);
      })
      .catch((err) => console.log('Error fetching conversations:', err));
  }

  joinConversationChannel = (conversationId: string) => {
    if (this.channel && this.channel.leave) {
      this.channel.leave(); // TODO: what's the best practice here?
    }

    // TODO: connect to latest conversation
    // TODO: should this be on this.state?
    // If no conversations exist, join lobby?? (which is just an open chat room???)
    // (this could be a fun little feature... lobby is where you can chat with... us??)
    this.channel = socket.channel(`conversation:${conversationId}`, {});

    this.channel.on('shout', (message) => {
      this.handleNewMessage(message);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        console.log('Joined successfully', res);
      })
      .receive('error', (err) => {
        console.log('Unable to join', err);
      });
  };

  handleSelectConversation = (id: string) => {
    const {conversations = []} = this.state;
    const conversation = conversations.find((conv) => conv.id === id);
    const messages = (conversation && conversation.messages) || [];

    this.setState(
      {
        selectedConversationId: id,
        messages: messages
          .map((msg: any) => {
            return {
              sender: msg.customer_id ? 'customer' : 'agent',
              body: msg.body,
              created_at: msg.created_at,
              customer_id: msg.customer_id,
            };
          })
          .sort((a, b) => +new Date(a.created_at) - +new Date(b.created_at)),
      },
      () => this.scrollToEl.scrollIntoView()
    );

    this.joinConversationChannel(id);
  };

  handleNewMessage = (message: Message) => {
    this.setState({messages: [...this.state.messages, message]}, () => {
      this.scrollToEl.scrollIntoView();
    });
  };

  handleMessageChange = (e: any) => {
    this.setState({message: e.target.value});
  };

  handleSendMessage = (e?: any) => {
    e && e.preventDefault();

    const {message, accountId, userId, selectedConversationId} = this.state;

    if (!this.channel || !message || message.trim().length === 0) {
      return;
    }

    this.channel.push('shout', {
      body: message,
      sender: 'agent',
      // created_at: new Date(),
      conversation_id: selectedConversationId,
      account_id: accountId,
      user_id: userId,
    });

    this.setState({message: ''});
  };

  render() {
    const {
      message,
      messages = [],
      conversations = [],
      selectedConversationId,
    } = this.state;

    return (
      <Layout>
        <Sider
          theme="light"
          width={280}
          style={{
            borderRight: '1px solid #f0f0f0',
            overflow: 'auto',
            height: '100vh',
            position: 'fixed',
            left: 0,
          }}
        >
          <Box p={3} sx={{borderBottom: '1px solid #f0f0f0'}}>
            <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
              Conversations
            </Title>
          </Box>
          <Box>
            {conversations.map((conversation, idx) => {
              const {id, customer, date, preview} = conversation;
              const isHighlighted = id === selectedConversationId;
              const {primary, red, green, gray} = colors;
              const color = [primary, red, green, gray[0]][idx % 4];

              return (
                <Box
                  key={id}
                  p={3}
                  sx={{
                    borderBottom: '1px solid #f0f0f0',
                    borderLeft: isHighlighted
                      ? `2px solid ${colors.primary}`
                      : null,
                    background: isHighlighted ? colors.blue[0] : null,
                    cursor: 'pointer',
                  }}
                  onClick={() => this.handleSelectConversation(id)}
                >
                  <Flex mb={2} sx={{justifyContent: 'space-between'}}>
                    <Flex sx={{alignItems: 'center'}}>
                      <Box mr={2}>
                        <SmileTwoTone
                          style={{fontSize: 16}}
                          twoToneColor={color}
                        />
                      </Box>
                      <Text strong>{customer}</Text>
                    </Flex>
                    <Text type="secondary">{date}</Text>
                  </Flex>
                  <Box
                    style={{
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    {preview}
                  </Box>
                </Box>
              );
            })}
          </Box>
        </Sider>
        <Layout style={{marginLeft: 280}}>
          <header
            style={{boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 2rem', zIndex: 1}}
          >
            <Flex py={3} px={4} backgroundColor={colors.white}>
              <Title level={4} style={{marginBottom: 0, marginTop: 4}}>
                Anonymous User
              </Title>
            </Flex>
          </header>
          <Content style={{overflowY: 'scroll'}}>
            <Box p={4} backgroundColor={colors.white} sx={{minHeight: '100%'}}>
              {messages.map((msg, key) => {
                // Slight hack
                const next = messages[key + 1];
                const isLastInGroup = next
                  ? msg.customer_id !== next.customer_id
                  : true;

                // TODO: fix `isMe` logic for multiple agents
                return (
                  <ChatMessage
                    key={key}
                    message={msg}
                    isMe={!msg.customer_id}
                    isLastInGroup={isLastInGroup}
                    shouldDisplayTimestamp={isLastInGroup}
                  />
                );
              })}
              <div ref={(el) => (this.scrollToEl = el)} />
            </Box>
          </Content>
          <Footer style={{padding: 0}}>
            <Box px={4} pt={0} pb={4} backgroundColor={colors.white}>
              <Box
                p={2}
                sx={{
                  border: '1px solid #f5f5f5',
                  borderRadius: 4,
                  boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
                }}
              >
                <Box mb={2}>
                  <TextArea
                    className="TextArea--transparent"
                    placeholder="Type your message here!"
                    autoSize={{minRows: 1, maxRows: 4}}
                    value={message}
                    onChange={this.handleMessageChange}
                  />
                </Box>
                <Flex sx={{justifyContent: 'flex-end'}}>
                  <Button type="primary" onClick={this.handleSendMessage}>
                    Send
                  </Button>
                </Flex>
              </Box>
            </Box>
          </Footer>
        </Layout>
      </Layout>
    );
  }
}

export default Dashboard;
