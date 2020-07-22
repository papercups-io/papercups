import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Channel} from 'phoenix';
import * as API from '../../api';
import {
  Button,
  colors,
  Content,
  Layout,
  Result,
  Sider,
  Text,
  Title,
} from '../common';
import {SmileOutlined} from '../icons';
import {socket} from '../../socket';
import {formatRelativeTime} from '../../utils';
import {Message, Conversation} from '../../types';
import Spinner from '../Spinner';
import ChatMessage from './ChatMessage';
import ConversationHeader from './ConversationHeader';
import ConversationItem from './ConversationItem';
import ConversationFooter from './ConversationFooter';

dayjs.extend(utc);

const EmptyMessagesPlaceholder = () => {
  return (
    <Box my={4}>
      <Result
        status="success"
        title="No messages"
        subTitle="Nothing to show here! Take a well-earned break 😊"
      />
    </Box>
  );
};

const GettingStartedRedirect = () => {
  return (
    <Box my={4}>
      <Result
        icon={<SmileOutlined />}
        title="No messages"
        subTitle="It looks like your widget hasn't been set up yet!"
        extra={
          <Link to="/account/getting-started">
            <Button type="primary">Get Started</Button>
          </Link>
        }
      />
      ,
    </Box>
  );
};

type Props = {
  title?: string;
  conversations: Array<Conversation>;
  account: any;
  currentUser: any;
  fetch: () => Promise<Array<Conversation>>;
  onRefresh?: () => void;
};
type State = {
  loading: boolean;
  showGetStarted: boolean;
  selectedConversationId: string | null;
  conversationIds: Array<string>;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  isUpdatingConversation: boolean;
};

class ConversationsContainer extends React.Component<Props, State> {
  scrollToEl: any = null;

  channel: Channel | null = null;

  state: State = {
    loading: true,
    showGetStarted: false,
    selectedConversationId: null,
    conversationIds: [],
    conversationsById: {},
    messagesByConversation: {},
    isUpdatingConversation: false,
  };

  async componentDidMount() {
    socket.connect();

    const {conversationIds = []} = await this.refreshConversationsData();

    const {account} = this.props;
    const {id: accountId} = account;

    this.joinNotificationChannel(accountId, conversationIds);
  }

  componentWillUnmount() {
    this.channel && this.channel.leave();
  }

  refreshConversationsData = async () => {
    this.setState({loading: true});

    const conversations = await this.props.fetch();

    if (!conversations || !conversations.length) {
      const {count: numAccountMessages} = await API.countMessages();
      const hasNoMessagesYet = numAccountMessages === 0;

      this.setState({
        showGetStarted: hasNoMessagesYet,
        conversationsById: {},
        messagesByConversation: {},
        conversationIds: [],
        selectedConversationId: null,
        loading: false,
      });

      return {
        conversationsById: {},
        messagesByConversation: {},
        conversationIds: [],
        selectedConversationId: null,
      };
    }

    return this.updateConversationsState(conversations);
  };

  updateConversationsState = (conversations: Array<any>) => {
    const {selectedConversationId} = this.state;

    const conversationsById = conversations.reduce((acc: any, conv: any) => {
      return {...acc, [conv.id]: conv};
    }, {});
    const messagesByConversation = conversations.reduce(
      (acc: any, conv: any) => {
        return {
          ...acc,
          [conv.id]: conv.messages.sort(
            (a: any, b: any) =>
              +new Date(a.created_at) - +new Date(b.created_at)
          ),
        };
      },
      {}
    );
    const conversationIds = Object.keys(conversationsById).sort(
      (a: string, b: string) => {
        const messagesA = messagesByConversation[a];
        const messagesB = messagesByConversation[b];
        const x = messagesA[messagesA.length - 1];
        const y = messagesB[messagesB.length - 1];

        return +new Date(y?.created_at) - +new Date(x?.created_at);
      }
    );
    const [recentConversationId] = conversationIds;
    const updatedSelectedId =
      selectedConversationId && conversationsById[selectedConversationId]
        ? selectedConversationId
        : recentConversationId;

    this.setState(
      {
        conversationsById,
        messagesByConversation,
        conversationIds,
        selectedConversationId: updatedSelectedId,
        loading: false,
      },
      () => this.scrollToEl.scrollIntoView()
    );

    return {
      conversationsById,
      messagesByConversation,
      conversationIds,
      selectedConversationId,
    };
  };

  joinNotificationChannel = (
    accountId: string,
    conversationIds: Array<string>
  ) => {
    if (this.channel && this.channel.leave) {
      this.channel.leave(); // TODO: what's the best practice here?
    }

    // TODO: If no conversations exist, should we create a conversation with us
    // so new users can play around with the chat right away and give us feedback?
    this.channel = socket.channel(`notification:${accountId}`, {
      ids: conversationIds,
    });

    this.channel.on('shout', (message) => {
      this.handleNewMessage(message);
    });

    this.channel.on('conversation', ({id: conversationId}) => {
      this.handleNewConversation(conversationId);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        console.log('Joined successfully', res);

        this.handleConversationRead(this.state.selectedConversationId);
      })
      .receive('error', (err) => {
        console.log('Unable to join', err);
      });
  };

  handleConversationRead = (conversationId: string | null) => {
    if (!this.channel || !conversationId) {
      return;
    }

    this.channel
      .push('read', {
        conversation_id: conversationId,
      })
      .receive('ok', (res) => {
        console.log('Marked as read!');

        const {conversationsById} = this.state;
        const current = conversationsById[conversationId];

        // Optimistic update
        this.setState({
          conversationsById: {
            ...conversationsById,
            [conversationId]: {...current, read: true},
          },
        });
      });
  };

  handleNewConversation = async (conversationId?: string) => {
    if (!this.channel || !conversationId) {
      return;
    }

    this.channel.push('watch', {
      conversation_id: conversationId,
    });

    const conversations = await this.props.fetch();

    this.updateConversationsState(conversations);
  };

  handleSelectConversation = (id: string) => {
    this.setState({selectedConversationId: id}, () => {
      this.handleConversationRead(id);
      this.scrollToEl.scrollIntoView();
    });
  };

  handleNewMessage = (message: Message) => {
    console.log('New message!', message);

    const {
      messagesByConversation,
      conversationIds,
      selectedConversationId,
      conversationsById,
    } = this.state;
    const {conversation_id: conversationId} = message;
    const existing = messagesByConversation[conversationId] || [];
    const update = {
      ...messagesByConversation,
      [conversationId]: [...existing, message],
    };
    const updatedConversationIds = [
      conversationId,
      ...conversationIds.filter((id) => id !== conversationId),
    ];

    this.setState(
      {
        messagesByConversation: update,
        conversationIds: updatedConversationIds,
      },
      () => {
        if (selectedConversationId === conversationId) {
          this.handleConversationRead(selectedConversationId);

          this.scrollToEl.scrollIntoView();
        } else if (selectedConversationId) {
          const selected = conversationsById[selectedConversationId];

          this.setState({
            conversationsById: {
              ...conversationsById,
              [conversationId]: {...selected, read: false},
            },
          });
        }
      }
    );
  };

  handleSendMessage = (message: string) => {
    const {account, currentUser} = this.props;
    const {selectedConversationId} = this.state;
    const {id: accountId} = account;
    const {id: userId} = currentUser;

    if (!this.channel || !message || message.trim().length === 0) {
      return;
    }

    this.channel.push('shout', {
      body: message,
      user_id: userId,
      conversation_id: selectedConversationId,
      account_id: accountId,
      sender: 'agent', // TODO: remove?
    });
  };

  formatMessage = (message: any) => {
    return {
      ...message,
      sender: message.customer_id ? 'customer' : 'agent',
    };
  };

  formatConversation = (conversation: any, messages: Array<any>) => {
    const recent = messages[messages.length - 1];
    const created = dayjs.utc(recent.created_at);
    const date = formatRelativeTime(created);

    return {
      ...conversation,
      customer: 'Anonymous User',
      date: date || '1d', // TODO
      preview: recent && recent.body ? recent.body : '...',
      messages: messages,
    };
  };

  handleUpdateConversation = async (conversationId: string, params: any) => {
    this.setState({isUpdatingConversation: true});

    const {conversationsById} = this.state;
    const existing = conversationsById[conversationId];

    // Optimistic update
    this.setState({
      conversationsById: {
        ...conversationsById,
        [conversationId]: {...existing, ...params},
      },
    });

    try {
      await API.updateConversation(conversationId, {
        conversation: params,
      });

      await this.refreshConversationsData();
    } catch (err) {
      // Revert
      this.setState({
        conversationsById: conversationsById,
      });
    }

    this.setState({isUpdatingConversation: false});
  };

  handleCloseConversation = (conversationId: string) => {
    this.handleUpdateConversation(conversationId, {status: 'closed'});
  };

  handleReopenConversation = (conversationId: string) => {
    this.handleUpdateConversation(conversationId, {status: 'open'});
  };

  handleMarkPriority = (conversationId: string) => {
    this.handleUpdateConversation(conversationId, {priority: 'priority'});
  };

  handleMarkUnpriority = (conversationId: string) => {
    this.handleUpdateConversation(conversationId, {priority: 'not_priority'});
  };

  handleAssignUser = (conversationId: string, userId: string) => {
    this.handleUpdateConversation(conversationId, {assignee_id: userId});
  };

  render() {
    const {account, currentUser} = this.props;
    const users = (account && account.users) || [];
    const {
      loading,
      showGetStarted,
      selectedConversationId,
      conversationIds = [],
      conversationsById = {},
      messagesByConversation = {},
    } = this.state;

    // TODO: add loading state

    const messages = selectedConversationId
      ? messagesByConversation[selectedConversationId]
      : [];
    const selectedConversation = selectedConversationId
      ? conversationsById[selectedConversationId]
      : null;

    return (
      <Layout style={{background: colors.white}}>
        <Sider
          theme="light"
          width={280}
          style={{
            borderRight: '1px solid #f0f0f0',
            overflow: 'auto',
            height: '100vh',
            position: 'fixed',
            left: 200,
          }}
        >
          <Box p={3} sx={{borderBottom: '1px solid #f0f0f0'}}>
            <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
              {this.props.title || 'Conversations'}
            </Title>
          </Box>

          <Box>
            {conversationIds.length ? (
              conversationIds.map((conversationId, idx) => {
                const conversation = conversationsById[conversationId];
                const messages = messagesByConversation[conversationId];
                const isHighlighted = conversationId === selectedConversationId;
                const {gold, red, green, gray} = colors;
                // TODO: come up with a better way to make colors/avatars consistent
                const color = [gold, red, green, gray[0]][idx % 4];

                return (
                  <ConversationItem
                    key={conversationId}
                    conversation={conversation}
                    messages={messages}
                    isHighlighted={isHighlighted}
                    color={color}
                    onSelectConversation={this.handleSelectConversation}
                  />
                );
              })
            ) : (
              <Box p={3}>
                <Text type="secondary">
                  {loading ? 'Loading...' : 'No conversations'}
                </Text>
              </Box>
            )}
          </Box>
        </Sider>
        <Layout style={{marginLeft: 280, background: colors.white}}>
          <ConversationHeader
            conversation={selectedConversation}
            users={users}
            onAssignUser={this.handleAssignUser}
            onMarkPriority={this.handleMarkPriority}
            onRemovePriority={this.handleMarkUnpriority}
            onCloseConversation={this.handleCloseConversation}
            onReopenConversation={this.handleReopenConversation}
          />

          <Content style={{overflowY: 'scroll'}}>
            {loading ? (
              <Flex
                sx={{
                  flex: 1,
                  justifyContent: 'center',
                  alignItems: 'center',
                  height: '100%',
                }}
              >
                <Spinner size={40} />
              </Flex>
            ) : (
              <Box
                p={4}
                backgroundColor={colors.white}
                sx={{minHeight: '100%'}}
              >
                {messages.length ? (
                  messages.map((message: any, key: number) => {
                    // Slight hack
                    const msg = this.formatMessage(message);
                    const next = messages[key + 1];
                    const isMe = msg.user_id && msg.user_id === currentUser.id;
                    const isLastInGroup = next
                      ? msg.customer_id !== next.customer_id
                      : true;

                    // TODO: fix `isMe` logic for multiple agents
                    return (
                      <ChatMessage
                        key={key}
                        message={msg}
                        isMe={isMe}
                        isLastInGroup={isLastInGroup}
                        shouldDisplayTimestamp={isLastInGroup}
                      />
                    );
                  })
                ) : showGetStarted ? (
                  <GettingStartedRedirect />
                ) : (
                  <EmptyMessagesPlaceholder />
                )}
                <div ref={(el) => (this.scrollToEl = el)} />
              </Box>
            )}
          </Content>

          {selectedConversation && (
            <ConversationFooter onSendMessage={this.handleSendMessage} />
          )}
        </Layout>
      </Layout>
    );
  }
}

export default ConversationsContainer;
