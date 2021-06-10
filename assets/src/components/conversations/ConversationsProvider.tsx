import React, {useContext} from 'react';
import {debounce, throttle} from 'lodash';
import {Socket} from 'phoenix';
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

type Inboxes = {
  all: {
    open: string[];
    assigned: string[];
    priority: string[];
    closed: string[];
  };
  bySource: {
    [key: string]: string[] | undefined;
  };
};

const getInboxesInitialState = () => ({
  all: {
    open: [],
    assigned: [],
    priority: [],
    closed: [],
  },
  bySource: {},
});

export const ConversationsContext = React.createContext<{
  loading: boolean;
  account: Account | null;
  currentUser: User | null;
  isNewUser: boolean;

  conversationsById: {[key: string]: any};
  messagesByConversation: {[key: string]: any};
  currentlyOnline: {[key: string]: any};
  inboxes: Inboxes;

  getUnreadCount: (conversationIds: string[]) => number;
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
  conversationsById: {},
  messagesByConversation: {},
  currentlyOnline: {},
  inboxes: getInboxesInitialState(),

  getUnreadCount: () => 0,

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

type Props = {socket: Socket} & React.PropsWithChildren<{}>;
type State = {
  loading: boolean;
  account: Account | null;
  currentUser: User | null;
  isNewUser: boolean;
  inboxes: Inboxes;

  selectedConversationId: string | null;
  conversationsById: {[key: string]: Conversation};
  messagesByConversation: {[key: string]: any};
  presence: PhoenixPresence;
};

export class ConversationsProvider extends React.Component<Props, State> {
  state: State = {
    loading: true,
    account: null,
    currentUser: null,
    isNewUser: false,
    inboxes: getInboxesInitialState(),
    selectedConversationId: null,
    conversationsById: {},
    messagesByConversation: {},
    presence: {},
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

    this.notificationManager = new ConversationNotificationManager(
      this.props.socket,
      {
        accountId,
        onNewMessage: this.handleNewMessage,
        onNewConversation: this.handleNewConversation,
        onConversationUpdated: this.debouncedConversationUpdate,
        onPresenceInit: this.handlePresenceInit,
        onPresenceDiff: this.handlePresenceDiff,
      }
    );
    this.notificationManager.connect();

    await this.fetchAllConversations();
  }

  componentDidUpdate(prev: Props) {
    if (prev.socket !== this.props.socket && this.state.account) {
      this.notificationManager = new ConversationNotificationManager(
        this.props.socket,
        {
          accountId: this.state.account.id,
          onNewMessage: this.handleNewMessage,
          onNewConversation: this.handleNewConversation,
          onConversationUpdated: this.debouncedConversationUpdate,
          onPresenceInit: this.handlePresenceInit,
          onPresenceDiff: this.handlePresenceDiff,
        }
      );
      this.notificationManager.connect();
    }
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
    const sortedConversationIds = this.getSortedConversationIds(
      conversationsById
    );

    return {
      conversationsById,
      messagesByConversation,
      conversationIds: sortedConversationIds,
    };
  };

  updateConversationState = (conversations: Array<Conversation>) => {
    const {conversationsById, messagesByConversation} = this.state;
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
    const inboxes = this.getInboxes(updatedConversationsById);

    return this.setState({
      ...updates,
      inboxes,
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

  getSortedConversationIds = (conversationsById: {
    [key: string]: Conversation;
  }) => {
    return Object.keys(conversationsById).sort((x: string, y: string) => {
      const a = conversationsById[x];
      const b = conversationsById[y];
      const left = a.last_activity_at
        ? +new Date(a.last_activity_at)
        : -Infinity;
      const right = b.last_activity_at
        ? +new Date(b.last_activity_at)
        : -Infinity;

      return right - left;
    });
  };

  getSortedConversations = (conversationsById: {
    [key: string]: Conversation;
  }) => {
    const conversationsIds = this.getSortedConversationIds(conversationsById);
    return conversationsIds.map((id) => conversationsById[id]);
  };

  getInboxes = (conversationsById: {[key: string]: Conversation}): Inboxes => {
    const conversations = this.getSortedConversations(conversationsById);
    const openConversations = this.getOpenConversations(conversations);
    const assignedConversations = this.getAssignedConversations(
      openConversations
    );
    const priorityConversations = this.getPriorityConversations(
      openConversations
    );
    const closedConservations = this.getClosedConservations(conversations);
    const inboxesBySource = this.getInboxesBySource(openConversations);

    return {
      all: {
        open: this.getConversationIds(openConversations),
        assigned: this.getConversationIds(assignedConversations),
        priority: this.getConversationIds(priorityConversations),
        closed: this.getConversationIds(closedConservations),
      },
      bySource: {
        ...inboxesBySource,
      },
    };
  };

  getInboxesBySource = (conversations: Conversation[]) => {
    return conversations.reduce((acc, conversation) => {
      const {id, source} = conversation;

      if (!source) {
        return acc;
      }

      return {
        ...acc,
        [source]: (acc[source] ?? []).concat(id),
      };
    }, {} as {[source: string]: string[]});
  };

  getConversationIds = (conversations: Conversation[]): string[] => {
    return conversations.map((c) => c.id);
  };

  getOpenConversations = (conversations: Conversation[]) => {
    return conversations.filter(
      (conversation) => conversation.status === 'open'
    );
  };

  getClosedConservations = (conversations: Conversation[]) => {
    return conversations.filter(
      (conversation) => conversation.status === 'closed'
    );
  };

  getAssignedConversations = (conversations: Conversation[]) => {
    const {currentUser} = this.state;
    return conversations.filter(
      (conversation) => conversation.assignee_id === currentUser?.id
    );
  };

  getPriorityConversations = (conversations: Conversation[]) => {
    return conversations.filter(
      (conversation) => conversation.priority === 'priority'
    );
  };

  getUnreadCount = (conversationIds: string[]) => {
    const {conversationsById} = this.state;
    const conversations = conversationIds.map((id) => conversationsById[id]);
    return conversations.filter((conversation) => !conversation.read).length;
  };

  render() {
    const {
      loading,
      account,
      currentUser,
      inboxes,
      isNewUser,
      conversationsById,
      messagesByConversation,
      presence,
    } = this.state;

    return (
      <ConversationsContext.Provider
        value={{
          loading,
          account,
          currentUser,
          isNewUser,
          conversationsById,
          messagesByConversation,
          inboxes,
          currentlyOnline: presence,

          getUnreadCount: this.getUnreadCount,

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
