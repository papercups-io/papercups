import {Channel, Socket} from 'phoenix';
import logger from '../../logger';
import {Conversation, Message} from '../../types';
import {PhoenixPresence, PresenceDiff} from '../../presence';

type Config = {
  accountId: string;
  onNewMessage: (message: Message) => void;
  onNewConversation: (id: string) => void;
  onConversationUpdated: (id: string, updates: Partial<Conversation>) => void;
  onPresenceInit: (presence: PhoenixPresence) => void;
  onPresenceDiff: (diff: PresenceDiff) => void;
};

/**
 * ConversationNotificationManager manages the socket and channel used for
 * connecting the React app with the Phoenix server for real-time messaging.
 */
class ConversationNotificationManager {
  config: Config;
  socket: Socket;
  channel: Channel | null = null;

  constructor(socket: Socket, config: Config) {
    this.socket = socket;
    this.config = config;
  }

  connect() {
    this.joinChannel();
  }

  disconnect() {
    this.channel?.leave();
  }

  joinChannel() {
    const {
      accountId,
      onConversationUpdated,
      onNewConversation,
      onNewMessage,
      onPresenceDiff,
      onPresenceInit,
    } = this.config;

    if (this.channel && this.channel.leave) {
      logger.debug(
        'Channel already exists. Leaving channel before connecting',
        this.channel
      );
      this.channel.leave(); // TODO: what's the best practice here?
    }

    // TODO: If no conversations exist, should we create a conversation with us
    // so new users can play around with the chat right away and give us feedback?
    this.channel = this.socket.channel(`notification:${accountId}`, {});

    // TODO: rename to message:created?
    this.channel.on('shout', onNewMessage);

    // TODO: fix race condition between this event and `shout` above
    this.channel.on('conversation:created', ({id, _conversation}) => {
      onNewConversation(id);
    });

    // // TODO: can probably use this for more things
    this.channel.on('conversation:updated', ({id, updates}) => {
      onConversationUpdated(id, updates);
    });

    this.channel.on('presence_state', onPresenceInit);

    this.channel.on('presence_diff', onPresenceDiff);

    this.channel
      .join()
      .receive('ok', (res) => {
        logger.debug('Joined channel successfully', this.channel);
      })
      .receive('error', (err) => {
        logger.error('Unable to join channel', err);
        // TODO: double check that this works (retries after 10s)
        setTimeout(() => this.connect(), 10000);
      });
  }

  markConversationAsRead(
    conversationId: string,
    onSuccess: (res: any) => void
  ) {
    this.channel
      ?.push('read', {
        conversation_id: conversationId,
      })
      .receive('ok', onSuccess);
  }

  sendMessage(message: Partial<Message>, callbackFn?: () => void) {
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

    if (callbackFn && typeof callbackFn === 'function') {
      callbackFn();
    }
  }
}

export default ConversationNotificationManager;
