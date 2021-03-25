import React, {useContext} from 'react';
import {Channel, Socket} from 'phoenix';
import {debounce, throttle} from 'lodash';
import * as API from '../../api';
import {notification} from '../common';
import {Account, Conversation, Message, User} from '../../types';
import {
  isWindowHidden,
  sortConversationMessages,
  updateQueryParams,
} from '../../utils';
import {SOCKET_URL} from '../../socket';
import logger from '../../logger';

export const ConversationsContext = React.createContext<{
  loading: boolean;
  account: Account | null;
  currentUser: User | null;
  isNewUser: boolean;

  all: Array<string>;
  mine: Array<string>;
  priority: Array<string>;
  closed: Array<string>;
  unreadByCategory: any;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  currentlyOnline: {[key: string]: any};

  isCustomerOnline: (customerId: string) => boolean;

  onSelectConversation: (id: string | null) => any;
  onUpdateConversation: (id: string, params: any) => Promise<any>;
  onDeleteConversation: (id: string) => Promise<any>;
  onSendMessage: (message: Partial<Message>, cb?: () => void) => any;

  onSetConversations: (conversations: Array<Conversation>) => Array<string>;
  onSetSingleConversation: (conversation: Conversation) => Array<string>;

  fetchAllConversations: () => Promise<Array<string>>;
  fetchMyConversations: () => Promise<Array<string>>;
  fetchPriorityConversations: () => Promise<Array<string>>;
  fetchClosedConversations: () => Promise<Array<string>>;
  // TODO: should this be different?
  fetchConversationById: (conversationId: string) => Promise<Array<string>>;
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
  currentlyOnline: {},

  isCustomerOnline: () => false,
  onSelectConversation: () => {},
  onSendMessage: () => {},

  onSetConversations: () => [],
  onSetSingleConversation: () => [],

  onUpdateConversation: () => Promise.resolve(),
  onDeleteConversation: () => Promise.resolve(),

  fetchAllConversations: () => Promise.resolve([]),
  fetchMyConversations: () => Promise.resolve([]),
  fetchPriorityConversations: () => Promise.resolve([]),
  fetchClosedConversations: () => Promise.resolve([]),
  fetchConversationById: () => Promise.resolve([]),
});

export const useConversations = () => useContext(ConversationsContext);

type ConversationBucket = 'all' | 'mine' | 'priority' | 'closed';

type PresenceMetadata = {online_at?: string; phx_ref: string};
type PhoenixPresence = {
  [key: string]: {
    metas: Array<PresenceMetadata>;
  } | null;
};
type PresenceDiff = {
  joins: PhoenixPresence;
  leaves: PhoenixPresence;
};

export const updatePresenceWithJoiners = (
  joiners: PhoenixPresence,
  currentState: PhoenixPresence
): PhoenixPresence => {
  // Update our presence state by adding all the joiners, represented by
  // keys like "customer:1a2b3c", "user:123", etc.
  // The `metas` represent the metadata of each presence. A single user/customer
  // can have multiple `metas` if logged into multiple devices/windows.
  let result = {...currentState};

  Object.keys(joiners).forEach((key) => {
    const existing = result[key];
    const update = joiners[key];

    // `metas` is how Phoenix tracks each individual presence
    if (!update || !update.metas) {
      throw new Error(`Unexpected join state: ${update}`);
    }

    if (existing && existing.metas) {
      result[key] = {metas: [...existing.metas, ...update.metas]};
    } else {
      result[key] = {metas: update.metas};
    }
  });

  return result;
};

export const updatePresenceWithExiters = (
  exiters: PhoenixPresence,
  currentState: PhoenixPresence
): PhoenixPresence => {
  // Update our presence state by removing all the exiters, represented by
  // keys like "customer:1a2b3c", "user:123", etc. We currently indicate an
  // "exit" by setting their key to `null`.
  // The `metas` represent the metadata of each presence. A single user/customer
  // can have multiple `metas` if logged into multiple devices/windows.
  let result = {...currentState};

  Object.keys(exiters).forEach((key) => {
    const existing = result[key];
    const update = exiters[key];

    // `metas` is how Phoenix tracks each individual presence
    if (!update || !update.metas) {
      throw new Error(`Unexpected leave state: ${update}`);
    }

    if (existing && existing.metas) {
      const remaining = existing.metas.filter((meta: PresenceMetadata) => {
        return update.metas.some(
          (m: PresenceMetadata) => meta.phx_ref !== m.phx_ref
        );
      });

      result[key] = remaining.length ? {metas: remaining} : null;
    } else {
      result[key] = null;
    }
  });

  return result;
};

type Props = React.PropsWithChildren<{}>;
type State = {
  loading: boolean;
  account: Account | null;
  currentUser: User | null;
  isNewUser: boolean;

  selectedConversationId: string | null;
  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  presence: PhoenixPresence;

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
    presence: {},

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
    this.setState({
      currentUser,
      account,
      isNewUser: numTotalMessages === 0,
    });
    const {id: accountId} = account;

    this.joinNotificationChannel(accountId);
  }

  componentWillUnmount() {
    if (this.channel && this.channel.leave) {
      this.channel.leave();
    }

    if (this.socket && this.socket.disconnect) {
      this.socket.disconnect();
    }
  }

  joinNotificationChannel = (accountId: string) => {
    if (this.socket && this.socket.disconnect) {
      logger.debug('Existing socket:', this.socket);
      this.socket.disconnect();
    }

    this.socket = new Socket(SOCKET_URL, {
      params: {token: API.getAccessToken()},
    });

    this.socket.connect();
    // TODO: attempt refreshing access token?
    this.socket.onError(
      throttle(
        () =>
          logger.error('Error connecting to socket. Try refreshing the page.'),
        30 * 1000 // throttle every 30 secs
      )
    );

    if (this.channel && this.channel.leave) {
      logger.debug('Existing channel:', this.channel);
      this.channel.leave(); // TODO: what's the best practice here?
    }

    // TODO: If no conversations exist, should we create a conversation with us
    // so new users can play around with the chat right away and give us feedback?
    this.channel = this.socket.channel(`notification:${accountId}`, {});

    // TODO: rename to message:created?
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
      this.debouncedConversationUpdate(id, updates);
    });

    this.channel.on('presence_state', (state) => {
      this.handlePresenceState(state);
    });

    this.channel.on('presence_diff', (diff) => {
      this.handlePresenceDiff(diff);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        logger.debug('Joined channel successfully', res);
      })
      .receive('error', (err) => {
        logger.error('Unable to join', err);
        // TODO: double check that this works (retries after 10s)
        setTimeout(() => this.joinNotificationChannel(accountId), 10000);
      });
  };

  handlePresenceState = (state: PhoenixPresence) => {
    this.setState({presence: state});
  };

  handlePresenceDiff = (diff: PresenceDiff) => {
    const {joins, leaves} = diff;
    const {presence} = this.state;

    const withJoins = updatePresenceWithJoiners(joins, presence);
    const withLeaves = updatePresenceWithExiters(leaves, presence);
    const combined = {...withJoins, ...withLeaves};
    const latest = Object.keys(combined).reduce((acc, key: string) => {
      if (!combined[key]) {
        return acc;
      }

      return {...acc, [key]: combined[key]};
    }, {} as PhoenixPresence);

    this.setState({presence: latest});
  };

  isCustomerOnline = (customerId: string) => {
    if (!customerId) {
      return false;
    }

    const {presence = {}} = this.state;
    const key = `customer:${customerId}`;

    return !!(presence && presence[key]);
  };

  playNotificationSound = async (volume: number) => {
    try {
      const file = '/alert-v2.mp3';
      const audio = new Audio(file);
      audio.volume = volume;

      await audio?.play();
    } catch (err) {
      logger.error('Failed to play notification sound:', err);
    }
  };

  throttledNotificationSound = throttle(
    (volume = 0.2) => this.playNotificationSound(volume),
    10 * 1000, // throttle every 10 secs so we don't get spammed with sounds
    {trailing: false}
  );

  handleNewMessage = async (message: Message) => {
    logger.debug('New message!', message);

    const {messagesByConversation} = this.state;
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
      () =>
        this.debouncedNewMessagesCallback(message, {
          isFirstMessage: existingMessages.length === 0,
        })
    );
  };

  debouncedNewMessagesCallback = debounce(
    (message: Message, {isFirstMessage}: {isFirstMessage: boolean}) => {
      const {selectedConversationId, conversationsById} = this.state;
      const {
        conversation_id: conversationId,
        customer_id: customerId,
      } = message;

      if (isWindowHidden(document || window.document)) {
        // Play a slightly louder sound if this is the first message
        const volume = isFirstMessage ? 0.2 : 0.1;

        this.throttledNotificationSound(volume);
      }
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
          !!customerId && conversation && conversation.status === 'open';

        this.setState({
          conversationsById: {
            ...conversationsById,
            [conversationId]: {...conversation, read: false},
          },
        });

        if (shouldDisplayAlert) {
          notification.open({
            message: 'New message',
            description: (
              <a href={`/conversations/all?cid=${conversationId}`}>
                {message.body}
              </a>
            ),
          });
        }
      }
    },
    1000
  );

  handleConversationRead = (conversationId: string | null) => {
    if (!this.channel || !conversationId) {
      return;
    }

    this.channel
      .push('read', {
        conversation_id: conversationId,
      })
      .receive('ok', (res) => {
        logger.debug('Marked as read!', {res, conversationId});

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
    logger.debug('Listening to new conversation:', conversationId);

    await this.fetchAllConversations();
    await this.throttledNotificationSound();
  };

  debouncedConversationUpdate = debounce(
    (id: string, updates: Partial<Conversation>) => {
      const {conversationsById} = this.state;
      const conversation = conversationsById[id];

      this.setState({
        conversationsById: {
          ...conversationsById,
          [id]: {...conversation, ...updates},
        },
      });

      return this.fetchAllConversations();
    },
    400
  );

  handleSelectConversation = (id: string | null) => {
    this.setState({selectedConversationId: id}, () => {
      if (!id) {
        return;
      }

      const conversation = this.state.conversationsById[id];

      if (conversation && !conversation.read) {
        this.handleConversationRead(id);
      }

      updateQueryParams({cid: id});
    });
  };

  handleSendMessage = (message: Partial<Message>, cb?: () => void) => {
    if (!message || !message.conversation_id) {
      throw new Error(
        `Invalid message ${message} - a \`conversation_id\` is required.`
      );
    }

    const {body, file_ids} = message;
    const hasEmptyBody = !body || body.trim().length === 0;
    const hasNoAttachments = !file_ids || file_ids.length === 0;

    if (!this.channel || (hasEmptyBody && hasNoAttachments)) {
      return;
    }

    this.channel.push('shout', {
      ...message,
      sent_at: new Date().toISOString(),
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

  handleDeleteConversation = async (conversationId: string) => {
    const {conversationsById} = this.state;

    try {
      await API.deleteConversation(conversationId);

      delete conversationsById[conversationId];
    } catch (err) {
      // Revert state if there's an error
      this.setState({
        conversationsById: conversationsById,
      });
    }
  };

  formatConversationState = (conversations: Array<Conversation>) => {
    const conversationsById = conversations.reduce(
      (acc: any, conv: Conversation) => {
        return {...acc, [conv.id]: conv};
      },
      {}
    );
    const messagesByConversation = conversations.reduce(
      (acc: any, conv: Conversation) => {
        const {messages = []} = conv;

        return {
          ...acc,
          [conv.id]: sortConversationMessages(messages),
        };
      },
      {}
    );
    const sortedConversationIds = Object.keys(conversationsById).sort(
      (x: string, y: string) => {
        const a = conversationsById[x];
        const b = conversationsById[y];
        const left = a.last_activity_at
          ? +new Date(a.last_activity_at)
          : -Infinity;
        const right = b.last_activity_at
          ? +new Date(b.last_activity_at)
          : -Infinity;

        return right - left;
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
    type?: ConversationBucket
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

    // TODO: double check this logic
    const conversationIds = Object.keys(updatedConversationsById).sort(
      (x: string, y: string) => {
        // TODO: DRY up this logic in other places
        const a = updates.conversationsById[x];
        const b = updates.conversationsById[y];
        const left = a.last_activity_at
          ? +new Date(a.last_activity_at)
          : -Infinity;
        const right = b.last_activity_at
          ? +new Date(b.last_activity_at)
          : -Infinity;

        return right - left;
      }
    );

    const allConversations = conversationIds.map(
      (id) => updates.conversationsById[id]
    );
    const openConversations = allConversations.filter(
      (c) => c.status === 'open'
    );
    const all = openConversations.map((c) => c.id);
    const mine = openConversations
      .filter((c) => c.assignee_id === currentUserId && c.status === 'open')
      .map((c) => c.id);
    const priority = openConversations
      .filter((c) => c.priority === 'priority' && c.status === 'open')
      .map((c) => c.id);
    const closed = allConversations
      .filter((c) => c.status !== 'open')
      .map((c) => c.id);

    return this.setState({
      ...updates,
      all,
      mine,
      priority,
      closed,
    });
  };

  handleSetConversations = (conversations: Array<Conversation>) => {
    const {conversationIds} = this.formatConversationState(conversations);
    this.updateConversationState(conversations);

    return conversationIds;
  };

  fetchAllConversations = async (): Promise<Array<string>> => {
    const {data: conversations} = await API.fetchAllConversations();
    const conversationIds = this.handleSetAllConversations(conversations);

    return conversationIds;
  };

  handleSetAllConversations = (conversations: Array<Conversation>) => {
    return this.handleSetConversations(conversations);
  };

  fetchConversationById = async (
    conversationId: string
  ): Promise<Array<string>> => {
    const conversation = await API.fetchConversation(conversationId);
    const conversationIds = this.handleSetSingleConversation(conversation);

    return conversationIds;
  };

  handleSetSingleConversation = (conversation: Conversation) => {
    const conversations = [conversation];

    return this.handleSetConversations(conversations);
  };

  fetchMyConversations = async (): Promise<Array<string>> => {
    const {currentUser} = this.state;

    if (!currentUser) {
      return [];
    }

    const {id: currentUserId} = currentUser;
    const {data: conversations} = await API.fetchMyConversations(currentUserId);
    const conversationIds = this.handleSetMyConversations(conversations);

    return conversationIds;
  };

  handleSetMyConversations = (conversations: Array<Conversation>) => {
    return this.handleSetConversations(conversations);
  };

  fetchPriorityConversations = async (): Promise<Array<string>> => {
    const {data: conversations} = await API.fetchPriorityConversations();
    const conversationIds = this.handleSetPriorityConversations(conversations);

    return conversationIds;
  };

  handleSetPriorityConversations = (conversations: Array<Conversation>) => {
    return this.handleSetConversations(conversations);
  };

  fetchClosedConversations = async (): Promise<Array<string>> => {
    const {data: conversations} = await API.fetchClosedConversations();
    const conversationIds = this.handleSetClosedConversations(conversations);

    return conversationIds;
  };

  handleSetClosedConversations = (conversations: Array<Conversation>) => {
    return this.handleSetConversations(conversations);
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
      presence,
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
          currentlyOnline: presence,

          isCustomerOnline: this.isCustomerOnline,

          onSelectConversation: this.handleSelectConversation,
          onUpdateConversation: this.handleUpdateConversation,
          onDeleteConversation: this.handleDeleteConversation,
          onSendMessage: this.handleSendMessage,

          onSetConversations: this.handleSetConversations,
          onSetSingleConversation: this.handleSetSingleConversation,

          fetchAllConversations: this.fetchAllConversations,
          fetchConversationById: this.fetchConversationById,
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
