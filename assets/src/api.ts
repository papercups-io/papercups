import request from 'superagent';
import qs from 'query-string';
import {getAuthTokens} from './storage';
import {Conversation, Tag, User} from './types';

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

export type ResetPasswordParams = {
  password: string;
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

export const verifyUserEmail = async (verificationToken: string) => {
  return request
    .post(`/api/verify_email`)
    .send({token: verificationToken})
    .then((res) => res.body.data);
};

export const sendPasswordResetEmail = async (email: string) => {
  return request
    .post(`/api/reset_password`)
    .send({email})
    .then((res) => res.body.data);
};

export const attemptPasswordReset = async (
  passwordResetToken: string,
  {password, passwordConfirmation}: ResetPasswordParams
) => {
  return request
    .put(`/api/reset_password`)
    .send({
      password,
      password_confirmation: passwordConfirmation,
      token: passwordResetToken,
    })
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

export const fetchCustomers = async (
  filters = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/customers`)
    .query(filters)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchCustomer = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/customers/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateCustomer = async (
  id: string,
  updates: Record<string, any>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/customers/${id}`)
    .set('Authorization', token)
    .send({
      customer: updates,
    })
    .then((res) => res.body.data);
};

export const createNewCompany = async (
  params: Record<string, any>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/companies`)
    .send({company: params})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchCompanies = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/companies`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchCompany = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/companies/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateCompany = async (
  id: string,
  updates: Record<string, any>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/companies/${id}`)
    .set('Authorization', token)
    .send({company: updates})
    .then((res) => res.body.data);
};

export const deleteCompany = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request.delete(`/api/companies/${id}`).set('Authorization', token);
};

export const createNewConversation = async (
  customerId: string,
  params?: Record<any, any>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/conversations`)
    .set('Authorization', token)
    .send({
      conversation: {
        customer_id: customerId,
        ...params,
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
  updates: Record<string, any>,
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
  updates: Record<string, any>,
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
  updates: Record<string, any>,
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

export const fetchConversation = async (
  id: string,
  token = getAccessToken()
): Promise<Conversation> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchPreviousConversation = async (
  id: string,
  token = getAccessToken()
): Promise<Conversation> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations/${id}/previous`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchRelatedConversations = async (
  id: string,
  token = getAccessToken()
): Promise<Array<Conversation>> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations/${id}/related`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchSlackConversationThreads = async (
  conversationId: string,
  token = getAccessToken()
): Promise<Array<Conversation>> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack_conversation_threads`)
    .query({conversation_id: conversationId})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const generateShareConversationToken = async (
  conversationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/conversations/${conversationId}/share`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchSharedConversation = async (
  id: string,
  token: string
): Promise<Conversation> => {
  if (!token) {
    throw new Error('Access denied!');
  }

  return request
    .get(`/api/conversations/shared`)
    .query({token, conversation_id: id})
    .then((res) => res.body.data);
};

export const updateConversation = async (
  conversationId: string,
  updates: Record<string, any>,
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

export const createNewMessage = async (
  conversationId: string,
  message: any,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/messages`)
    .set('Authorization', token)
    .send({
      message: {
        conversation_id: conversationId,
        sent_at: new Date().toISOString(),
        ...message,
      },
    })
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

export const fetchSlackAuthorization = async (
  type = 'reply',
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack/authorization`)
    .query({type})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteSlackAuthorization = async (
  authorizationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/slack/authorizations/${authorizationId}`)
    .set('Authorization', token);
};

export const fetchSlackChannels = async (
  query = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack/channels`)
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchGmailAuthorization = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/gmail/authorization`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export type EmailParams = {
  recipient: string;
  subject: string;
  message: string;
};

export const sendGmailNotification = async (
  {recipient, subject, message}: EmailParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/gmail/send`)
    .send({recipient, subject, message})
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
  type: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack/oauth`)
    .query({code, type})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const authorizeGmailIntegration = async (
  code: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/gmail/oauth`)
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

export const createSubscriptionPlan = async (
  plan: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/billing`)
    .send({plan})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateSubscriptionPlan = async (
  plan: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/billing`)
    .send({plan})
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

export const disableAccountUser = async (
  userId: number | string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/users/${userId}/disable`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const enableAccountUser = async (
  userId: number | string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/users/${userId}/enable`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchCustomerNotes = async (
  customerId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/notes`)
    .query({customer_id: customerId})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createCustomerNote = async (
  customerId: string,
  body: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/notes`)
    .set('Authorization', token)
    .send({
      note: {
        body,
        customer_id: customerId,
      },
    })
    .then((res) => res.body.data);
};

export const deleteCustomerNote = async (
  noteId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request.delete(`/api/notes/${noteId}`).set('Authorization', token);
};

export const fetchAllTags = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/tags`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchTagById = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/tags/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createTag = async (
  tag: Partial<Tag>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/tags`)
    .send({tag})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteTag = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/tags/${id}`)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const addConversationTag = async (
  conversationId: string,
  tagId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/conversations/${conversationId}/tags`)
    .send({tag_id: tagId})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const removeConversationTag = async (
  conversationId: string,
  tagId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/conversations/${conversationId}/tags/${tagId}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const addCustomerTag = async (
  customerId: string,
  tagId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/customers/${customerId}/tags`)
    .send({tag_id: tagId})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const removeCustomerTag = async (
  customerId: string,
  tagId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/customers/${customerId}/tags/${tagId}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

type BrowserSessionFilters = {
  sessionIds?: Array<string>;
  customerId?: string;
  isActive?: boolean;
  limit?: number;
};

export const fetchBrowserSessions = async (
  {customerId, isActive, limit = 100, sessionIds = []}: BrowserSessionFilters,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/browser_sessions`)
    .query(
      qs.stringify(
        {
          ids: sessionIds,
          customer_id: customerId,
          active: isActive,
          limit,
        },
        {arrayFormat: 'bracket'}
      )
    )
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const countBrowserSessions = async (
  {customerId, isActive}: BrowserSessionFilters,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/browser_sessions/count`)
    .query(
      qs.stringify(
        {
          customer_id: customerId,
          active: isActive,
        },
        {arrayFormat: 'bracket'}
      )
    )
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchBrowserSession = async (
  id: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/browser_sessions/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

type ReportingFilters = {
  from_date?: string | null;
  to_date?: string | null;
};

export const fetchReportingData = async (
  filters = {} as ReportingFilters,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/reporting`)
    .query(filters)
    .set('Authorization', token)
    .then((res) => res.body.data);
};
