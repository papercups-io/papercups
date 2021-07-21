import {colors} from '../common';
import {Account, Conversation, Message, User} from '../../types';

const {primary, gold, red, green, purple, magenta} = colors;

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
