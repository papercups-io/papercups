import React, {useContext} from 'react';
import {Channel, Socket} from 'phoenix';
import * as API from '../../api';
import logger from '../../logger';
import {noop} from '../../utils';
import {Conversation, Message} from '../../types';
import {
  PhoenixPresence,
  PresenceDiff,
  updatePresenceWithDiff,
} from '../../presence';

export const NotificationsContext = React.createContext<{
  channel: Channel | null;
  presence: PhoenixPresence | null;
  isCustomerOnline: (customerId: string) => boolean;
  handleSendMessage: (message: Partial<Message>) => Promise<any>;
  handleConversationSeen: (
    conversationId: string,
    onSuccess?: (result: any) => void
  ) => void;
  // Listeners
  onNewMessage: (cb: (message: Message) => void) => () => void;
  onNewConversation: (cb: (id: string) => void) => () => void;
  onConversationUpdated: (
    cb: (id: string, updates: Partial<Conversation>) => void
  ) => () => void;
}>({
  channel: null,
  presence: null,
  isCustomerOnline: () => false,
  handleSendMessage: () => Promise.resolve({}),
  handleConversationSeen: () => {},
  onNewMessage: () => () => {},
  onNewConversation: () => () => {},
  onConversationUpdated: () => () => {},
});

export const useNotifications = () => useContext(NotificationsContext);

type Props = {
  socket: Socket;
  onNewMessage?: (message: Message) => void;
  onNewConversation?: (id: string) => void;
  onConversationUpdated?: (id: string, updates: Partial<Conversation>) => void;
} & React.PropsWithChildren<{}>;
type State = {
  presence: PhoenixPresence | null;
};

export class NotificationsProvider extends React.Component<Props, State> {
  channel: Channel | null = null;
  timeout: any = null;

  state: State = {
    presence: null,
  };

  async componentDidMount() {
    const {account_id: accountId} = await API.me();
    const channel = `notification:${accountId}`;

    this.connect(channel);
  }

  componentWillUnmount() {
    this.disconnect();
  }

  connect = (channel: string) => {
    const {
      socket,
      onNewMessage = noop,
      onNewConversation = noop,
      onConversationUpdated = noop,
    } = this.props;

    this.channel = socket.channel(channel, {}) as Channel;
    // TODO: rename to message:created?
    this.channel.on('shout', (payload) => onNewMessage(payload));
    // TODO: fix race condition between this event and `shout` above
    this.channel.on('conversation:created', ({id}) => onNewConversation(id));
    // TODO: can probably use this for more things
    this.channel.on('conversation:updated', ({id, updates}) =>
      onConversationUpdated(id, updates)
    );

    this.channel.on('presence_state', this.handlePresenceInit);
    this.channel.on('presence_diff', this.handlePresenceDiff);

    this.channel.onError(() => {
      logger.error(
        'Error connecting to notification channel. Attempting reconnect after 1s...'
      );

      this.timeout = setTimeout(() => this.connect(channel), 1000);
    });

    this.channel
      .join()
      .receive('ok', (data) => {
        logger.debug('Joined channel successfully:', data);

        clearTimeout(this.timeout);
      })
      .receive('error', (err) => {
        logger.error('Unable to join channel:', err);
        logger.info('Attempting reconnect after 1s...');
        // TODO: double check that this works (retries after 1s)
        this.timeout = setTimeout(() => this.connect(channel), 1000);
      })
      .receive('timeout', (data) => {
        logger.error('Connection to channel timed out:', data);
        logger.info('Attempting reconnect after 1s...');
        // TODO: double check that this works (retries after 1s)
        this.timeout = setTimeout(() => this.connect(channel), 1000);
      });
  };

  disconnect = () => {
    this.channel?.leave();
  };

  onNewMessage = (cb: (payload: Message) => void) => {
    this.channel?.on('shout', (payload) => cb(payload));

    // Reset defaults
    return () => {
      const {onNewMessage = noop} = this.props;

      this.channel?.off('shout');
      this.channel?.on('shout', (payload) => onNewMessage(payload));
    };
  };

  onNewConversation = (cb: (conversationId: string) => void) => {
    this.channel?.on('conversation:created', ({id: conversationId}) =>
      cb(conversationId)
    );

    // Reset defaults
    return () => {
      const {onNewConversation = noop} = this.props;

      this.channel?.off('conversation:created');
      this.channel?.on('conversation:created', ({id: conversationId}) =>
        onNewConversation(conversationId)
      );
    };
  };

  onConversationUpdated = (
    cb: (conversationId: string, updates: Partial<Conversation>) => void
  ) => {
    this.channel?.on(
      'conversation:updated',
      ({id: conversationId, updates = {}}) => cb(conversationId, updates)
    );

    // Reset defaults
    return () => {
      const {onConversationUpdated = noop} = this.props;

      this.channel?.off('conversation:updated');
      this.channel?.on('conversation:updated', ({id, updates}) =>
        onConversationUpdated(id, updates)
      );
    };
  };

  handlePresenceInit = (presence: PhoenixPresence) => {
    this.setState({presence});
  };

  handlePresenceDiff = (diff: PresenceDiff) => {
    const {presence} = this.state;

    if (!presence) {
      return null;
    }

    const updated = updatePresenceWithDiff(presence, diff);

    this.setState({presence: updated});
  };

  isCustomerOnline = (customerId: string) => {
    const {presence} = this.state;

    if (!customerId || !presence) {
      return false;
    }

    const key = `customer:${customerId}`;

    return !!(presence && presence[key]);
  };

  handleConversationSeen = (
    conversationId: string,
    onSuccess: (result: any) => void = noop
  ) => {
    this.channel
      ?.push('read', {conversation_id: conversationId})
      .receive('ok', onSuccess);
  };

  handleSendMessage = async (message: Partial<Message>) => {
    if (!message || !message.conversation_id) {
      throw new Error(
        `Invalid message ${message} - a \`conversation_id\` is required.`
      );
    }

    const {body, file_ids} = message;
    const hasEmptyBody = !body || body.trim().length === 0;
    const hasNoAttachments = !file_ids || file_ids.length === 0;

    if (hasEmptyBody && hasNoAttachments) {
      logger.debug('Skipped sending invalid message:', message);

      return null;
    }

    return API.createNewMessage(message);
  };

  render() {
    return (
      <NotificationsContext.Provider
        value={{
          channel: this.channel,
          presence: this.state.presence || {},
          isCustomerOnline: this.isCustomerOnline,
          handleSendMessage: this.handleSendMessage,
          handleConversationSeen: this.handleConversationSeen,
          // listeners
          onNewMessage: this.onNewMessage,
          onNewConversation: this.onNewConversation,
          onConversationUpdated: this.onConversationUpdated,
        }}
      >
        {this.props.children}
      </NotificationsContext.Provider>
    );
  }
}

export default NotificationsProvider;
