import React, {useContext} from 'react';
import {debounce, throttle} from 'lodash';
import * as API from '../../api';
import {notification} from '../common';
import {Account, Conversation, Message, User} from '../../types';
import {
  isWindowHidden,
  sortConversationMessages,
  updateQueryParams,
} from '../../utils';
import logger from '../../logger';
import {
  PhoenixPresence,
  PresenceDiff,
  updatePresenceWithDiff,
} from '../../presence';
import ConversationNotificationManager from './ConversationNotificationManager';

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

  fetchAllConversations: () => Promise<Array<string>>;
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

  onUpdateConversation: () => Promise.resolve(),
  onDeleteConversation: () => Promise.resolve(),

  fetchAllConversations: () => Promise.resolve([]),
  fetchConversationById: () => Promise.resolve([]),
});

export const useConversations = () => useContext(ConversationsContext);

type ConversationBucket = 'all' | 'mine' | 'priority' | 'closed';

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

  notificationManager: ConversationNotificationManager | null = null;

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

    this.notificationManager = new ConversationNotificationManager({
      accountId,
      onNewMessage: this.handleNewMessage,
      onNewConversation: this.handleNewConversation,
      onConversationUpdated: this.debouncedConversationUpdate,
      onPresenceInit: this.handlePresenceInit,
      onPresenceDiff: this.handlePresenceDiff,
    });
    this.notificationManager.connect();
  }

  componentWillUnmount() {
    this.notificationManager?.disconnect();
  }

  handlePresenceInit = (state: PhoenixPresence) => {
    this.setState({presence: state});
  };

  handlePresenceDiff = (diff: PresenceDiff) => {
    this.setState({
      presence: updatePresenceWithDiff(this.state.presence, diff),
    });
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
    if (!conversationId) {
      return;
    }

    this.notificationManager?.markConversationAsRead(conversationId, (res) => {
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
      logger.debug('Handling conversation update:', id, updates);

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
    this.notificationManager?.sendMessage(message, cb);
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
      await API.archiveConversation(conversationId);

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
    const conversationIds = this.handleSetConversations(conversations);

    return conversationIds;
  };

  fetchConversationById = async (
    conversationId: string
  ): Promise<Array<string>> => {
    const conversation = await API.fetchConversation(conversationId);
    const conversationIds = this.handleSetConversations([conversation]);

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

          fetchAllConversations: this.fetchAllConversations,
          fetchConversationById: this.fetchConversationById,
        }}
      >
        {this.props.children}
      </ConversationsContext.Provider>
    );
  }
}
