import React, {useContext} from 'react';
import {Channel, Socket} from 'phoenix';
import * as API from '../../api';
import {notification} from '../common';
import {Conversation, Message} from '../../types';
import {sleep} from '../../utils';
import {SOCKET_URL} from '../../socket';

export const ConversationsContext = React.createContext<{
  loading: boolean;
  account: any;
  currentUser: any;
  isNewUser: boolean;

  all: Array<string>;
  mine: Array<string>;
  priority: Array<string>;
  closed: Array<string>;
  unreadByCategory: any;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};

  onSelectConversation: (id: string | null) => any;
  onUpdateConversation: (id: string, params: any) => Promise<any>;
  onSendMessage: (
    message: string,
    conversationId: string,
    cb?: () => void
  ) => any;

  fetchAllConversations: () => Promise<Array<string>>;
  fetchMyConversations: () => Promise<Array<string>>;
  fetchPriorityConversations: () => Promise<Array<string>>;
  fetchClosedConversations: () => Promise<Array<string>>;
}>({
  loading: true,
  account: null,
  currentUser: null,
  isNewUser: false,

  all: [],
  mine: [],
  priority: [],
  closed: [],
  unreadByCategory: {},
  conversationsById: {},
  messagesByConversation: {},

  onSelectConversation: () => {},
  onSendMessage: () => {},
  onUpdateConversation: () => Promise.resolve(),

  fetchAllConversations: () => Promise.resolve([]),
  fetchMyConversations: () => Promise.resolve([]),
  fetchPriorityConversations: () => Promise.resolve([]),
  fetchClosedConversations: () => Promise.resolve([]),
});

export const useConversations = () => useContext(ConversationsContext);

type ConversationBucket = 'all' | 'mine' | 'priority' | 'closed';

type Props = React.PropsWithChildren<{}>;
type State = {
  loading: boolean;
  account: any | null;
  currentUser: any | null;
  isNewUser: boolean;

  selectedConversationId: string | null;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};

  all: Array<string>;
  mine: Array<string>;
  priority: Array<string>;
  closed: Array<string>;
};

export class ConversationsProvider extends React.Component<Props, State> {
  state: State = {
    loading: true,
    account: null,
    currentUser: null,
    isNewUser: false,

    selectedConversationId: null,
    conversationsById: {},
    messagesByConversation: {},

    all: [],
    mine: [],
    priority: [],
    closed: [],
  };

  socket: Socket | null = null;
  channel: Channel | null = null;

  async componentDidMount() {
    const [currentUser, account, numTotalMessages] = await Promise.all([
      API.me(),
      API.fetchAccountInfo(),
      API.countMessages().then((r) => r.count),
    ]);
    this.setState({currentUser, account, isNewUser: numTotalMessages === 0});
    const conversationIds = await this.fetchAllConversations();
    const {id: accountId} = account;

    this.joinNotificationChannel(accountId, conversationIds);
  }

  joinNotificationChannel = (
    accountId: string,
    conversationIds: Array<string>
  ) => {
    if (this.socket && this.socket.disconnect) {
      console.log('Existing socket:', this.socket);
      this.socket.disconnect();
    }

    this.socket = new Socket(SOCKET_URL, {
      params: {token: API.getAccessToken()},
    });
    this.socket.connect();

    if (this.channel && this.channel.leave) {
      console.log('Existing channel:', this.channel);
      this.channel.leave(); // TODO: what's the best practice here?
    }

    // TODO: If no conversations exist, should we create a conversation with us
    // so new users can play around with the chat right away and give us feedback?
    this.channel = this.socket.channel(`notification:${accountId}`, {
      ids: conversationIds,
    });

    // TODO: rename?
    this.channel.on('shout', (message) => {
      // Handle new message
      this.handleNewMessage(message);
    });

    // TODO: fix race condition between this event and `shout` above
    this.channel.on('conversation:created', ({id, conversation}) => {
      // Handle conversation created
      this.handleNewConversation(id);
    });

    // TODO: can probably use this for more things
    this.channel.on('conversation:updated', ({id, updates}) => {
      // Handle conversation updated
      this.handleConversationUpdated(id, updates);
    });

    this.channel.on('presence_state', (state) => {
      console.log('Presence state:', state);
    });

    this.channel.on('presence_diff', (state) => {
      console.log('Presence diff:', state);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        console.log('Joined successfully', res);
      })
      .receive('error', (err) => {
        console.log('Unable to join', err);
        // TODO: double check that this works (retries after 10s)
        setTimeout(
          () => this.joinNotificationChannel(accountId, conversationIds),
          10000
        );
      });
  };

  handleNewMessage = async (message: Message) => {
    console.log('New message!', message);

    const {
      messagesByConversation,
      selectedConversationId,
      conversationsById,
    } = this.state;
    const {conversation_id: conversationId} = message;
    const existingMessages = messagesByConversation[conversationId] || [];
    const updatedMessagesByConversation = {
      ...messagesByConversation,
      [conversationId]: [...existingMessages, message],
    };

    this.setState(
      {
        messagesByConversation: updatedMessagesByConversation,
      },
      () => {
        // TODO: this is a bit hacky... there's probably a better way to
        // handle listening for changes on conversation records...
        if (selectedConversationId === conversationId) {
          // If the new message matches the id of the selected conversation,
          // mark it as read right away and scroll to the latest message
          this.handleConversationRead(selectedConversationId);
        } else {
          // Otherwise, find the updated conversation and mark it as unread
          const conversation = conversationsById[conversationId];
          const shouldDisplayAlert =
            conversation && conversation.status === 'open';

          this.setState({
            conversationsById: {
              ...conversationsById,
              [conversationId]: {...conversation, read: false},
            },
          });

          if (shouldDisplayAlert) {
            notification.open({
              message: 'New message',
              description: message.body,
            });
          }
        }
      }
    );
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
        console.log('Marked as read!', {res, conversationId});

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

    this.channel.push('watch:one', {
      conversation_id: conversationId,
    });

    // FIXME: this is a hack to fix the race condition with the `shout` event
    await sleep(1000);
    await this.fetchAllConversations();
  };

  handleJoinMultipleConversations = (conversationIds: Array<string>) => {
    if (!this.channel) {
      return;
    }

    this.channel.push('watch:many', {
      conversation_ids: conversationIds,
    });
  };

  handleConversationUpdated = (id: string, updates: any) => {
    const {conversationsById} = this.state;
    const conversation = conversationsById[id];

    this.setState({
      conversationsById: {
        ...conversationsById,
        [id]: {...conversation, ...updates},
      },
    });
  };

  handleSelectConversation = (id: string | null) => {
    this.setState({selectedConversationId: id}, () => {
      if (!id) {
        return;
      }

      const conversation = this.state.conversationsById[id];

      if (conversation && !conversation.read) {
        this.handleConversationRead(id);
      }
    });
  };

  handleSendMessage = (
    message: string,
    conversationId: string,
    cb?: () => void
  ) => {
    if (!this.channel || !message || message.trim().length === 0) {
      return;
    }

    this.channel.push('shout', {
      body: message,
      conversation_id: conversationId,
    });

    if (cb && typeof cb === 'function') {
      cb();
    }
  };

  handleUpdateConversation = async (conversationId: string, params: any) => {
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
    } catch (err) {
      // Revert state if there's an error
      this.setState({
        conversationsById: conversationsById,
      });
    }
  };

  formatConversationState = (conversations: Array<Conversation>) => {
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
    const sortedConversationIds = Object.keys(conversationsById).sort(
      (a: string, b: string) => {
        const messagesA = messagesByConversation[a];
        const messagesB = messagesByConversation[b];
        const x = messagesA[messagesA.length - 1];
        const y = messagesB[messagesB.length - 1];

        return +new Date(y?.created_at) - +new Date(x?.created_at);
      }
    );

    return {
      conversationsById,
      messagesByConversation,
      conversationIds: sortedConversationIds,
    };
  };

  updateConversationState = (
    conversations: Array<Conversation>,
    type: ConversationBucket
  ) => {
    const {currentUser, conversationsById, messagesByConversation} = this.state;
    const currentUserId = currentUser ? currentUser.id : null;
    const state = this.formatConversationState(conversations);
    const updatedConversationsById = {
      ...conversationsById,
      ...state.conversationsById,
    };
    const updatedMessagesByConversation = {
      ...messagesByConversation,
      ...state.messagesByConversation,
    };

    const updates = {
      loading: false,
      conversationsById: updatedConversationsById,
      messagesByConversation: updatedMessagesByConversation,
    };

    switch (type) {
      case 'all':
        const conversations = state.conversationIds
          .map((id) => updates.conversationsById[id])
          .filter((c) => c.status === 'open');
        const all = conversations.map((c) => c.id);
        const mine = conversations
          .filter((c) => c.assignee_id === currentUserId && c.status === 'open')
          .map((c) => c.id);
        const priority = conversations
          .filter((c) => c.priority === 'priority' && c.status === 'open')
          .map((c) => c.id);

        return this.setState({
          ...updates,
          all,
          mine,
          priority,
        });
      case 'mine':
        return this.setState({
          ...updates,
          mine: state.conversationIds,
        });
      case 'priority':
        return this.setState({
          ...updates,
          priority: state.conversationIds,
        });
      case 'closed':
        return this.setState({
          ...updates,
          closed: state.conversationIds,
        });
    }
  };

  fetchAllConversations = async (): Promise<Array<string>> => {
    const conversations = await API.fetchAllConversations();
    const {conversationIds} = this.formatConversationState(conversations);

    this.updateConversationState(conversations, 'all');

    return conversationIds;
  };

  fetchMyConversations = async (): Promise<Array<string>> => {
    const {currentUser} = this.state;

    if (!currentUser) {
      return [];
    }

    const {id: currentUserId} = currentUser;
    const conversations = await API.fetchMyConversations(currentUserId);
    const {conversationIds} = this.formatConversationState(conversations);

    this.updateConversationState(conversations, 'mine');

    return conversationIds;
  };

  fetchPriorityConversations = async (): Promise<Array<string>> => {
    const conversations = await API.fetchPriorityConversations();
    const {conversationIds} = this.formatConversationState(conversations);

    this.updateConversationState(conversations, 'priority');

    return conversationIds;
  };

  fetchClosedConversations = async (): Promise<Array<string>> => {
    const conversations = await API.fetchClosedConversations();
    const {conversationIds} = this.formatConversationState(conversations);

    this.updateConversationState(conversations, 'closed');
    this.handleJoinMultipleConversations(conversationIds);

    return conversationIds;
  };

  getUnreadByCategory = () => {
    const {all, mine, priority, conversationsById} = this.state;

    return {
      all: all
        .map((id) => conversationsById[id])
        .filter((conv) => conv && !conv.read).length,
      mine: mine
        .map((id) => conversationsById[id])
        .filter((conv) => conv && !conv.read).length,
      priority: priority
        .map((id) => conversationsById[id])
        .filter((conv) => conv && !conv.read).length,
    };
  };

  render() {
    const {
      loading,
      account,
      currentUser,
      isNewUser,
      all,
      mine,
      priority,
      closed,
      conversationsById,
      messagesByConversation,
    } = this.state;
    const unreadByCategory = this.getUnreadByCategory();

    return (
      <ConversationsContext.Provider
        value={{
          loading,
          account,
          currentUser,
          isNewUser,
          all,
          mine,
          priority,
          closed,
          unreadByCategory,
          conversationsById,
          messagesByConversation,

          onSelectConversation: this.handleSelectConversation,
          onUpdateConversation: this.handleUpdateConversation,
          onSendMessage: this.handleSendMessage,

          fetchAllConversations: this.fetchAllConversations,
          fetchMyConversations: this.fetchMyConversations,
          fetchPriorityConversations: this.fetchPriorityConversations,
          fetchClosedConversations: this.fetchClosedConversations,
        }}
      >
        {this.props.children}
      </ConversationsContext.Provider>
    );
  }
}
