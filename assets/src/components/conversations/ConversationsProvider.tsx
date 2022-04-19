import React, {useContext} from 'react';

import * as API from '../../api';
import {Conversation, Message} from '../../types';
import {mapConversationsById, mapMessagesByConversationId} from './support';
import {notification} from '../common';
import logger from '../../logger';

const defaultFilterCallback = () => true;

type Unread = {
  conversations: {
    open: number;
    assigned: number;
    priority: number;
    unread: number;
    unassigned: number;
    closed: number;
    mentioned: number;
  };
  inboxes: {
    [id: string]: number;
  };
};

export const ConversationsContext = React.createContext<{
  loading?: boolean;
  unread: Unread;
  getValidConversations: (
    filter?: (conversation: Conversation) => boolean
  ) => Array<Conversation>;
  getValidConversationsByIds: (
    conversationIds: Array<string>,
    filter?: (conversation: Conversation) => boolean
  ) => Array<Conversation>;
  fetchConversations: (
    query?: Record<string, any>
  ) => Promise<API.ConversationsListResponse>;
  fetchConversationById: (id: string) => Promise<Conversation | null>;
  updateConversationById: (
    id: string,
    updates: Record<any, any>
  ) => Promise<Conversation | null>;
  updateConversationAssignee: (
    id: string,
    userId: string | null
  ) => Promise<Conversation | null>;
  markConversationPriority: (id: string) => Promise<Conversation | null>;
  removeConversationPriority: (id: string) => Promise<Conversation | null>;
  closeConversation: (id: string) => Promise<Conversation | null>;
  reopenConversation: (id: string) => Promise<Conversation | null>;
  archiveConversationById: (id: string) => Promise<void>;
  getConversationById: (id: string | null) => Conversation | null;
  getMessagesByConversationId: (id: string | null) => Array<Message>;
  onNewMessage: (message: Message) => void;
  onNewConversation: (conversationId: string) => void;
  onConversationUpdated: (
    conversationId: string,
    updates: Record<string, any>
  ) => void;
}>({
  loading: false,
  unread: {
    conversations: {
      open: 0,
      assigned: 0,
      priority: 0,
      unread: 0,
      unassigned: 0,
      closed: 0,
      mentioned: 0,
    },
    inboxes: {},
  },
  getValidConversations: () => [],
  getValidConversationsByIds: () => [],
  fetchConversations: () =>
    Promise.resolve({
      data: [],
      next: null,
      previous: null,
      limit: null,
      total: null,
    }),
  fetchConversationById: () => Promise.resolve(null),
  updateConversationById: () => Promise.resolve(null),
  updateConversationAssignee: () => Promise.resolve(null),
  markConversationPriority: () => Promise.resolve(null),
  removeConversationPriority: () => Promise.resolve(null),
  closeConversation: () => Promise.resolve(null),
  reopenConversation: () => Promise.resolve(null),
  archiveConversationById: () => Promise.resolve(),
  getConversationById: () => null,
  getMessagesByConversationId: () => [],
  onNewMessage: () => {},
  onNewConversation: () => {},
  onConversationUpdated: () => {},
});

export const useConversations = () => useContext(ConversationsContext);

type Props = React.PropsWithChildren<{}>;
type State = {
  loading: boolean;
  connecting: boolean;
  conversationIds: Array<string>;
  conversationsById: {[id: string]: Conversation};
  messagesByConversationId: {[id: string]: Array<Message>};
  unread: Unread;
  pagination: API.PaginationOptions;
};

export class ConversationsProvider extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = {
      loading: true,
      connecting: false,

      conversationIds: [],
      conversationsById: {},
      messagesByConversationId: {},
      unread: {
        conversations: {
          open: 0,
          assigned: 0,
          priority: 0,
          unread: 0,
          unassigned: 0,
          closed: 0,
          mentioned: 0,
        },
        inboxes: {},
      },
      pagination: {
        previous: null,
        next: null,
        limit: undefined,
        total: undefined,
      },
    };
  }

  async componentDidMount() {
    await this.fetchConversations({status: 'open'});

    this.setState({loading: false});
  }

  // TODO: distinguish between partial updates (i.e. just updating some conversation fields)
  // versus full update (i.e. complete refresh of conversation/customer/messages data)?
  updateConversationState = (conversation: Conversation) => {
    const {id, messages = []} = conversation;
    const {
      conversationIds = [],
      conversationsById = {},
      messagesByConversationId = {},
    } = this.state;
    const cachedConversation = conversationsById[id] || {};
    const cachedMessages = messagesByConversationId[id] || [];

    this.setState({
      conversationIds: [...new Set([...conversationIds, id])],
      conversationsById: {
        ...conversationsById,
        [id]: {...cachedConversation, ...conversation},
      },
      messagesByConversationId: {
        ...messagesByConversationId,
        [id]:
          messages.length > cachedMessages.length ? messages : cachedMessages,
      },
    });
  };

  fetchConversations = async (
    query: Record<string, any> = {status: 'open'}
  ) => {
    try {
      const result = await API.fetchConversations(query);
      const {data: conversations = []} = result;
      const {
        conversationIds = [],
        conversationsById = {},
        messagesByConversationId = {},
      } = this.state;

      this.setState({
        conversationIds: [
          ...new Set([...conversationIds, ...conversations.map((c) => c.id)]),
        ],
        conversationsById: {
          ...conversationsById,
          ...mapConversationsById(conversations),
        },
        messagesByConversationId: {
          ...messagesByConversationId,
          ...mapMessagesByConversationId(conversations),
        },
      });

      await this.updateUnreadNotifications();

      return result;
    } catch (err) {
      logger.error('Failed to fetch conversations:', err);

      throw err;
    }
  };

  fetchConversationById = async (conversationId: string) => {
    try {
      const conversation = await API.fetchConversation(conversationId);
      this.updateConversationState(conversation);
      await this.updateUnreadNotifications();

      return conversation;
    } catch (err) {
      logger.error('Failed to fetch conversation:', conversationId, err);

      throw err;
    }
  };

  updateConversationById = async (
    conversationId: string,
    updates: Record<any, any>
  ) => {
    try {
      const conversation = await API.updateConversation(conversationId, {
        conversation: updates,
      });
      this.updateConversationState(conversation);

      return conversation;
    } catch (err) {
      logger.error(
        'Failed to update conversation:',
        conversationId,
        updates,
        err
      );

      throw err;
    }
  };

  updateConversationAssignee = async (
    conversationId: string,
    userId: string | null
  ) => this.updateConversationById(conversationId, {assignee_id: userId});

  markConversationPriority = async (conversationId: string) =>
    this.updateConversationById(conversationId, {priority: 'priority'});

  removeConversationPriority = async (conversationId: string) =>
    this.updateConversationById(conversationId, {priority: 'not_priority'});

  closeConversation = async (conversationId: string) =>
    this.updateConversationById(conversationId, {status: 'closed'});

  reopenConversation = async (conversationId: string) =>
    this.updateConversationById(conversationId, {status: 'open'});

  archiveConversationById = async (conversationId: string) => {
    try {
      await API.archiveConversation(conversationId);

      delete this.state.conversationsById[conversationId];
    } catch (err) {
      logger.error('Failed to archive conversation:', conversationId, err);

      throw err;
    }
  };

  getConversationById = (
    conversationId: string | null
  ): Conversation | null => {
    if (!conversationId) {
      return null;
    }

    const conversation = this.state.conversationsById[conversationId];

    if (!conversation) {
      // TODO: figure out the best way to avoid this... probably needs to be
      // handled on the server where we handle emitting events via channels)
      logger.debug(
        `[Warning] Missing conversation in cache for id: ${conversationId}`
      );

      return null;
    }

    const messages = this.getMessagesByConversationId(conversationId);

    return {...conversation, messages};
  };

  getValidConversationsByIds = (
    conversationIds: Array<string>,
    filter: (conversation: Conversation) => boolean = defaultFilterCallback
  ) => {
    return (
      conversationIds
        .map((id) => this.getConversationById(id))
        .filter(
          (conversation: Conversation | null): conversation is Conversation =>
            !!conversation
        )
        .map((conversation: Conversation) => {
          const messages = this.getMessagesByConversationId(conversation.id);

          return {...conversation, messages};
        })
        // TODO: figure out why some conversations get created without messages
        // .filter(({messages = []}) => messages && messages.length > 0)
        .sort((a: Conversation, b: Conversation) => {
          const x = a.last_activity_at || a.updated_at;
          const y = b.last_activity_at || b.updated_at;

          return +new Date(y) - +new Date(x);
        })
        .filter((conversation: Conversation) => filter(conversation))
    );
  };

  getValidConversations = (
    filter: (conversation: Conversation) => boolean = defaultFilterCallback
  ): Array<Conversation> => {
    const {conversationIds = []} = this.state;

    return this.getValidConversationsByIds(conversationIds, filter);
  };

  getMessagesByConversationId = (conversationId: string | null) => {
    if (!conversationId) {
      return [];
    }

    const messages = this.state.messagesByConversationId[conversationId];

    if (!messages) {
      // TODO: figure out the best way to avoid this... probably needs to be
      // handled on the server where we handle emitting events via channels)
      logger.debug(
        `[Warning] Missing messages in cache for conversation: ${conversationId}`
      );

      return [];
    }

    return messages;
  };

  addMessagesByConversationId = (
    conversationId: string,
    messages: Array<Message>
  ) => {
    return {
      ...this.state.messagesByConversationId,
      [conversationId]: [
        ...this.getMessagesByConversationId(conversationId),
        ...messages,
      ],
    };
  };

  handleNewMessage = (message: Message) => {
    const {id: messageId, conversation_id: conversationId} = message;
    const messages = this.getMessagesByConversationId(conversationId);
    // This may happen for the first message of a new conversation
    const isAlreadyCached = messages.some((msg) => msg.id === messageId);

    if (!isAlreadyCached) {
      this.setState({
        messagesByConversationId: {
          ...this.state.messagesByConversationId,
          [conversationId]: [...messages, message],
        },
      });
    }

    this.handleNewMessageNotification(message);
    this.updateUnreadNotifications();
  };

  handleNewMessageNotification = (message: Message) => {
    const {conversation_id: conversationId, customer_id: customerId} = message;
    const conversation = this.getConversationById(conversationId);
    const isClosed = conversation?.status === 'closed';
    const pathname = window.location.pathname || '';
    const isViewing =
      pathname.includes('conversations') && pathname.includes(conversationId);

    if (isViewing || !customerId || isClosed) {
      return;
    }

    const inboxId = conversation?.inbox_id ?? null;
    const url = inboxId
      ? `/inboxes/${inboxId}/conversations/${conversationId}`
      : `/conversations/all/${conversationId}`;

    notification.open({
      key: conversationId,
      message: 'New message',
      description: <a href={url}>{message.body}</a>,
    });
  };

  updateUnreadNotifications = async () => {
    // TODO: don't invoke this as aggressively
    const unread = await API.countUnreadConversations();

    this.setState({unread});
  };

  handleNewConversation = async (conversationId: string) => {
    const conversation = await this.fetchConversationById(conversationId);

    this.setState({
      conversationsById: {
        ...this.state.conversationsById,
        [conversationId]: conversation,
      },
    });

    this.updateUnreadNotifications();
  };

  handleConversationUpdated = async (
    conversationId: string,
    updates: Record<any, any>
  ) => {
    const existing = this.getConversationById(conversationId);

    if (existing) {
      this.setState({
        conversationsById: {
          ...this.state.conversationsById,
          [conversationId]: {
            ...existing,
            ...updates,
          },
        },
      });
    } else {
      const conversation = await this.fetchConversationById(conversationId);

      this.setState({
        conversationsById: {
          ...this.state.conversationsById,
          [conversationId]: conversation,
        },
      });
    }

    this.updateUnreadNotifications();
  };

  render() {
    const {loading, unread} = this.state;

    return (
      <ConversationsContext.Provider
        value={{
          loading,
          unread,
          getValidConversations: this.getValidConversations,
          getValidConversationsByIds: this.getValidConversationsByIds,
          fetchConversations: this.fetchConversations,
          fetchConversationById: this.fetchConversationById,
          updateConversationById: this.updateConversationById,
          updateConversationAssignee: this.updateConversationAssignee,
          markConversationPriority: this.markConversationPriority,
          removeConversationPriority: this.removeConversationPriority,
          closeConversation: this.closeConversation,
          reopenConversation: this.reopenConversation,
          archiveConversationById: this.archiveConversationById,
          getConversationById: this.getConversationById,
          getMessagesByConversationId: this.getMessagesByConversationId,
          onNewMessage: this.handleNewMessage,
          onNewConversation: this.handleNewConversation,
          onConversationUpdated: this.handleConversationUpdated,
        }}
      >
        {this.props.children}
      </ConversationsContext.Provider>
    );
  }
}
