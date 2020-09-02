import request from 'superagent';
import {getAuthTokens} from './storage';
import {Conversation, User} from './types';

// TODO: handle this on the server instead
function now() {
  const date = new Date();

  return new Date(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
    date.getUTCHours(),
    date.getUTCMinutes(),
    date.getUTCSeconds()
  );
}

export type LoginParams = {
  email: string;
  password: string;
};

export type RegisterParams = LoginParams & {
  companyName?: string;
  inviteToken?: string;
  passwordConfirmation: string;
};

export type WidgetSettingsParams = {
  id?: string;
  title: string;
  subtitle: string;
  color: string;
  greeting?: string;
  new_message_placeholder?: string;
};

export type EventSubscriptionParams = {
  webhook_url: string;
};

export const getAccessToken = (): string | null => {
  const tokens = getAuthTokens();

  return (tokens && tokens.token) || null;
};

export const getRefreshToken = (): string | null => {
  const tokens = getAuthTokens();

  return (tokens && tokens.renew_token) || null;
};

export const me = async (token = getAccessToken()): Promise<User> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/me`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const login = async ({email, password}: LoginParams) => {
  return request
    .post(`/api/session`)
    .send({user: {email, password}})
    .then((res) => res.body.data);
};

export const logout = async () => {
  return request.delete(`/api/session`).then((res) => res.body);
};

export const register = async ({
  companyName,
  inviteToken,
  email,
  password,
  passwordConfirmation,
}: RegisterParams) => {
  return request
    .post(`/api/registration`)
    .send({
      user: {
        company_name: companyName,
        invite_token: inviteToken,
        email,
        password,
        password_confirmation: passwordConfirmation,
      },
    })
    .then((res) => res.body.data);
};

export const renew = async (token = getRefreshToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/session/renew`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createNewCustomer = async (accountId: string) => {
  return request
    .post(`/api/customers`)
    .send({
      customer: {
        account_id: accountId,
        first_seen: now(),
        last_seen: now(),
      },
    }) // TODO: send over some metadata?
    .then((res) => res.body.data);
};

export const fetchCustomers = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/customers`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createNewConversation = async (
  accountId: string,
  customerId: string
) => {
  return request
    .post(`/api/conversations`)
    .send({
      conversation: {
        account_id: accountId,
        customer_id: customerId,
      },
    })
    .then((res) => res.body.data);
};

export const fetchAccountInfo = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/accounts/me`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateAccountInfo = async (
  updates: any,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/accounts/me`)
    .set('Authorization', token)
    .send({
      account: updates,
    })
    .then((res) => res.body.data);
};

export const fetchUserProfile = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/profile`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateUserProfile = async (
  updates: any,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/profile`)
    .set('Authorization', token)
    .send({
      user_profile: updates,
    })
    .then((res) => res.body.data);
};

export const fetchUserSettings = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get('/api/user_settings')
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateUserSettings = async (
  updates: any,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put('/api/user_settings')
    .set('Authorization', token)
    .send({
      user_settings: updates,
    })
    .then((res) => res.body.data);
};

export const fetchAllConversations = async (
  token = getAccessToken()
): Promise<Array<Conversation>> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations`)
    .query({status: 'open'})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchMyConversations = async (
  userId: number,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations`)
    .query({assignee_id: userId, status: 'open'})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchPriorityConversations = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations`)
    .query({priority: 'priority', status: 'open'})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchClosedConversations = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations`)
    .query({status: 'closed'})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateConversation = async (
  conversationId: string,
  updates: any,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/conversations/${conversationId}`)
    .set('Authorization', token)
    .send(updates)
    .then((res) => res.body.data);
};

export const deleteConversation = async (
  conversationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/conversations/${conversationId}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const countMessages = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/messages/count`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchCustomerConversations = async (
  customerId: string,
  accountId: string
) => {
  return request
    .get(`/api/conversations/customer`)
    .query({customer_id: customerId, account_id: accountId})
    .then((res) => res.body.data);
};

export const generateUserInvitation = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/user_invitations`)
    .send({user_invitation: {}})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchSlackAuthorization = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack/authorization`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchEventSubscriptions = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/event_subscriptions`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const verifyWebhookUrl = async (
  url: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/event_subscriptions/verify`)
    .set('Authorization', token)
    .send({url})
    .then((res) => res.body.data);
};

export const createEventSubscription = async (
  params: EventSubscriptionParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/event_subscriptions`)
    .set('Authorization', token)
    .send({
      event_subscription: params,
    })
    .then((res) => res.body.data);
};

export const updateEventSubscription = async (
  id: string,
  updates: EventSubscriptionParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/event_subscriptions/${id}`)
    .set('Authorization', token)
    .send({
      event_subscription: updates,
    })
    .then((res) => res.body.data);
};

export const deleteEventSubscription = async (
  id: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/event_subscriptions/${id}`)
    .set('Authorization', token);
};

export const authorizeSlackIntegration = async (
  code: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack/oauth`)
    .query({code})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateWidgetSettings = async (
  widgetSettingsParams: WidgetSettingsParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/widget_settings`)
    .send({widget_settings: widgetSettingsParams})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchDefaultPaymentMethod = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/payment_methods`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchBillingInfo = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/billing`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createPaymentMethod = async (
  paymentMethod: any,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/payment_methods`)
    .send({payment_method: paymentMethod})
    .set('Authorization', token)
    .then((res) => res.body.data);
};
