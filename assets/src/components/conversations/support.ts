import {colors} from '../common';
import {Account, Conversation, Message, User} from '../../types';
import logger from '../../logger';
import {throttle} from 'lodash';

const {primary, gold, red, green, purple, magenta} = colors;

export const mapConversationsById = (conversations: Array<Conversation>) => {
  return conversations.reduce((acc, conversation) => {
    const {id} = conversation;

    return {...acc, [id]: conversation};
  }, {} as {[id: string]: Conversation});
};

export const mapMessagesByConversationId = (
  conversations: Array<Conversation>
) => {
  return conversations.reduce((acc, {id, messages = []}) => {
    return {
      ...acc,
      // TODO: move sorting logic to server?
      [id]: messages.sort(
        (a, b) => +new Date(a.created_at) - +new Date(b.created_at)
      ),
    };
  }, {} as {[id: string]: Array<Message>});
};

export const getColorByUuid = (uuid?: string | null) => {
  if (!uuid) {
    return primary;
  }

  const colorIndex = parseInt(uuid, 32) % 5;
  const color = [gold, red, green, purple, magenta][colorIndex];

  return color;
};

export const isBotMessage = (message: Message) => {
  return message.type === 'bot';
};

export const isAgentMessage = (message: Message) => {
  return !isBotMessage(message) && !!message.user_id;
};

export const isUnreadConversation = (
  conversation: Conversation,
  currentUser: User | null
) => {
  if (!conversation.read) {
    return true;
  }

  const {mentions = []} = conversation;

  return mentions.some((mention) => {
    return mention.user_id === currentUser?.id && !mention.seen_at;
  });
};

export const getUserIdentifier = (user: User) => {
  const {display_name, full_name, email} = user;

  return display_name || full_name || email || 'Agent';
};

export const getUserProfilePhoto = (user: User) => {
  return user.profile_photo_url || null;
};

export const getSenderIdentifier = (
  message: Message,
  account?: Account | null
) => {
  const {user, customer} = message;

  if (isBotMessage(message)) {
    return account?.company_name || 'Bot';
  }

  if (user) {
    const {display_name, full_name, email} = user;

    return display_name || full_name || email || 'Agent';
  } else if (customer) {
    const {name, email} = customer;

    return name || email || 'Anonymous User';
  } else {
    return 'Anonymous User';
  }
};

export const getSenderProfilePhoto = (
  message: Message,
  account?: Account | null
) => {
  const {user, customer} = message;

  if (isBotMessage(message)) {
    return account?.company_logo_url || null;
  }

  if (user) {
    return user.profile_photo_url || null;
  } else if (customer) {
    return customer.profile_photo_url || null;
  } else {
    return null;
  }
};

export const playNotificationSound = async (volume: number) => {
  try {
    const file = '/alert-v2.mp3';
    const audio = new Audio(file);
    audio.volume = volume;

    await audio?.play();
  } catch (err) {
    logger.error('Failed to play notification sound:', err);
  }
};

export const throttledNotificationSound = throttle(
  (volume = 0.2) => playNotificationSound(volume),
  10 * 1000, // throttle every 10 secs so we don't get spammed with sounds
  {trailing: false}
);

export const getNextConversationId = (
  selectedConversationId: string | null,
  validConversationIds: Array<string>
) => {
  if (!validConversationIds || !validConversationIds.length) {
    return null;
  }

  const [first] = validConversationIds;

  if (!selectedConversationId) {
    return first;
  }

  const index = validConversationIds.indexOf(selectedConversationId);

  if (index === -1) {
    return first;
  }

  const max = validConversationIds.length - 1;
  const next = validConversationIds[Math.min(index + 1, max)];

  return next;
};

export const getPreviousConversationId = (
  selectedConversationId: string | null,
  validConversationIds: Array<string>
) => {
  if (!validConversationIds || !validConversationIds.length) {
    return null;
  }

  const [first] = validConversationIds;

  if (!selectedConversationId) {
    return first;
  }

  const index = validConversationIds.indexOf(selectedConversationId);

  if (index === -1) {
    return first;
  }

  const min = 0;
  const previous = validConversationIds[Math.max(index - 1, min)];

  return previous;
};

export const getNextSelectedConversationId = (
  selectedConversationId: string | null,
  validConversationIds: Array<string>
) => {
  if (!validConversationIds || !validConversationIds.length) {
    return null;
  }

  const [first] = validConversationIds;

  if (!selectedConversationId) {
    return first;
  }

  const index = validConversationIds.indexOf(selectedConversationId);

  if (index === -1) {
    return first;
  }

  const min = 0;
  const max = validConversationIds.length - 1;
  const next = validConversationIds[Math.min(index + 1, max)];
  const previous = validConversationIds[Math.max(index - 1, min)];

  if (index === min) {
    return next;
  } else if (index === max) {
    return previous;
  } else {
    const [selected = null] = [next, previous, first].filter(
      (opt) => !!opt && opt !== selectedConversationId
    );

    return selected;
  }
};
