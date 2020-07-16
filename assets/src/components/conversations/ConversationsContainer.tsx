import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Channel} from 'phoenix';
import * as API from '../../api';
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
} from '../common';
import {SmileTwoTone, StarFilled} from '../icons';
import ChatMessage from './ChatMessage';
import {socket} from '../../socket';
import {formatRelativeTime} from '../../utils';
import ConversationHeader from './ConversationHeader';
import ConversationItem from './ConversationItem';
import ConversationFooter from './ConversationFooter';

dayjs.extend(utc);

// NB: actual message records will look slightly different
type Message = {
  sender: string;
  body: string;
  created_at: string;
  customer_id: string;
  conversation_id: string;
};
// NB: actual conversation records will look different
type Conversation = {
  id: string;
  customer: string;
  date: string;
  preview: string;
  messages?: Array<Message>;
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
  message: string;
  selectedConversationId?: string | null;
  conversationIds: Array<string>;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  isUpdatingConversation: boolean;
};

class ConversationsContainer extends React.Component<Props, State> {
  scrollToEl: any = null;

  channel: Channel | null = null;

  state: State = {
    message: '',
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

  refreshConversationsData = async () => {
    const {selectedConversationId} = this.state;
    const conversations = await this.props.fetch();

    if (!conversations || !conversations.length) {
      // TODO: handle empty state better
      this.setState({
        conversationsById: {},
        messagesByConversation: {},
        conversationIds: [],
        selectedConversationId: null,
      });

      return {
        conversationsById: {},
        messagesByConversation: {},
        conversationIds: [],
        selectedConversationId: null,
      };
    }

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

    // TODO: If no conversations exist, join lobby?? (which is just an open chat room???)
    // (this could be a fun little feature... lobby is where you can chat with... us??)
    this.channel = socket.channel(`notification:${accountId}`, {
      ids: conversationIds,
    });

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
    this.setState({selectedConversationId: id}, () =>
      this.scrollToEl.scrollIntoView()
    );
  };

  handleNewMessage = (message: Message) => {
    console.log('New message!', message);

    const {messagesByConversation, conversationIds} = this.state;
    const {conversation_id: conversationId} = message;
    const existing = messagesByConversation[conversationId];
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
        this.scrollToEl.scrollIntoView();
      }
    );
  };

  handleMessageChange = (e: any) => {
    this.setState({message: e.target.value});
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
      sender: 'agent',
      // created_at: new Date(),
      conversation_id: selectedConversationId,
      account_id: accountId,
      user_id: userId,
    });
  };

  _handleSendMessage = (e?: any) => {
    e && e.preventDefault();

    const {account, currentUser} = this.props;
    const {message, selectedConversationId} = this.state;
    const {id: accountId} = account;
    const {id: userId} = currentUser;

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

  formatMessage = (message: any) => {
    return {
      sender: message.customer_id ? 'customer' : 'agent',
      body: message.body,
      created_at: message.created_at,
      customer_id: message.customer_id,
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
    const {account} = this.props;
    const users = (account && account.users) || [];
    const {
      message,
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

    console.log({selectedConversation});

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
            left: 80,
          }}
        >
          <Box p={3} sx={{borderBottom: '1px solid #f0f0f0'}}>
            <Title level={3} style={{marginBottom: 0, marginTop: 8}}>
              {this.props.title || 'Conversations'}
            </Title>
          </Box>
          <Box>
            {conversationIds.map((conversationId, idx) => {
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
            })}
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
            <Box p={4} backgroundColor={colors.white} sx={{minHeight: '100%'}}>
              {messages.map((message: any, key: number) => {
                // Slight hack
                const msg = this.formatMessage(message);
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

          {selectedConversation && (
            <ConversationFooter onSendMessage={this.handleSendMessage} />
          )}
        </Layout>
      </Layout>
    );
  }
}

export default ConversationsContainer;
