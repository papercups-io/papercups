import {Channel, Socket} from 'phoenix';
import {once, throttle} from 'lodash';

import logger from '../../logger';
import {Conversation, Message} from '../../types';
import {SOCKET_URL} from '../../socket';
import * as API from '../../api';
import {PhoenixPresence, PresenceDiff} from '../../presence';
import {notification} from '../common';

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

  constructor(config: Config) {
    this.socket = this.createNewSocket();
    this.config = config;
  }

  createNewSocket() {
    return new Socket(SOCKET_URL, {
      params: {token: API.getAccessToken()},
    });
  }

  connect() {
    this.connectToSocket();
    this.joinChannel();
  }

  disconnect() {
    logger.debug('Disconnecting from socket and leaving channel:', {
      socket: this.socket,
      channel: this.channel,
    });

    this.socket.disconnect();
    this.channel?.leave();
  }

  connectToSocket() {
    this.socket.onOpen(() => logger.debug('Successfully connected to socket!'));

    // TODO: attempt refreshing access token?
    this.socket.onError(
      throttle(
        () => {
          logger.error('Error connecting to socket. Try refreshing the page.');

          this.displayRefreshNotification();
        },
        30 * 1000 // throttle every 30 secs
      )
    );

    this.socket.connect();
  }

  // We use lodash's `once` utility to make sure this notification only gets displayed once
  displayRefreshNotification = once(() => {
    notification.error({
      message: "You've been disconnected.",
      duration: null,
      description: 'Please refresh the page to reconnect.',
    });
  });

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
        logger.debug('Joined channel successfully');
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
