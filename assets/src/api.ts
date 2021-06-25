import request from 'superagent';
import qs from 'query-string';
import {getAuthTokens} from './storage';
import {
  Account,
  BrowserSession,
  Conversation,
  Customer,
  CustomerNote,
  OnboardingStatus,
  GoogleAuthParams,
  GoogleIntegrationParams,
  Issue,
  Lambda,
  Tag,
  User,
  WidgetSettings,
} from './types';

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

export const createNewCustomer = async (
  accountId: string,
  params: Partial<Customer>
) => {
  return request
    .post(`/api/customers`)
    .send({
      customer: {
        first_seen: now(),
        last_seen_at: now(),
        ...params,
        account_id: accountId,
      },
    })
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
    .query(qs.stringify(filters, {arrayFormat: 'bracket'}))
    .set('Authorization', token)
    .then((res) => res.body);
};

export const fetchCustomer = async (
  id: string,
  query: {expand?: Array<string>} = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  const {expand = []} = query;

  return request
    .get(`/api/customers/${id}`)
    .query(qs.stringify({expand}, {arrayFormat: 'bracket'}))
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

export const deleteCustomer = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/customers/${id}`)
    .set('Authorization', token)
    .then((res) => res.body);
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

export const fetchAccountInfo = async (
  token = getAccessToken()
): Promise<Account> => {
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

export const deleteMyAccount = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/accounts/me`)
    .set('Authorization', token)
    .then((res) => res.body);
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

export type PaginationOptions = {
  limit?: number;
  next?: string | null;
  previous?: string | null;
  total?: number;
};

export type ConversationsListResponse = {
  data: Array<Conversation>;
  next: string | null;
  previous: string | null;
};

export const fetchConversations = async (
  query = {},
  token = getAccessToken()
): Promise<ConversationsListResponse> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/conversations`)
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const fetchAllConversations = async (
  query = {},
  token = getAccessToken()
) => {
  return fetchConversations({...query, status: 'open'}, token);
};

export const fetchMyConversations = async (
  userId: number,
  query = {},
  token = getAccessToken()
) => {
  return fetchConversations(
    {
      ...query,
      assignee_id: userId,
      status: 'open',
    },
    token
  );
};

export const fetchPriorityConversations = async (
  query = {},
  token = getAccessToken()
) => {
  return fetchConversations(
    {
      ...query,
      priority: 'priority',
      status: 'open',
    },
    token
  );
};

export const fetchClosedConversations = async (
  query = {},
  token = getAccessToken()
) => {
  return fetchConversations({...query, status: 'closed'}, token);
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
    .then((res) => res.body);
};

export const archiveConversation = async (
  conversationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/conversations/${conversationId}/archive`)
    .set('Authorization', token)
    .then((res) => res.body);
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

export const sendUserInvitationEmail = async (
  to_address: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/user_invitation_emails`)
    .send({to_address})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const sendSlackNotification = async (
  params: {
    text: string;
    type?: 'reply' | 'support';
    channel?: string;
  },
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/slack/notify`)
    .send(params)
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

export const updateSlackAuthorizationSettings = async (
  authorizationId: string,
  settings: Record<string, any>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/slack/authorizations/${authorizationId}/settings`)
    .send({settings})
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

export const fetchMattermostChannels = async (
  query = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/mattermost/channels`)
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createMattermostAuthorization = async (
  authorization = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/mattermost/auth`)
    .send({authorization})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchMattermostAuthorization = async (
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/mattermost/authorization`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteMattermostAuthorization = async (
  authorizationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/mattermost/authorizations/${authorizationId}`)
    .set('Authorization', token);
};

export const createTwilioAuthorization = async (
  authorization = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/twilio/auth`)
    .send({authorization})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchTwilioAuthorization = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/twilio/authorization`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteTwilioAuthorization = async (
  authorizationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/twilio/authorizations/${authorizationId}`)
    .set('Authorization', token);
};

export const sendTwilioSms = async (
  params: {to: string; body: string},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/twilio/send`)
    .send(params)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchGoogleAuthorization = async (
  query: GoogleIntegrationParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/google/authorization`)
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteGoogleAuthorization = async (
  authorizationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/google/authorizations/${authorizationId}`)
    .set('Authorization', token);
};

export const fetchGithubAuthorization = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/github/authorization`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteGithubAuthorization = async (
  authorizationId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/github/authorizations/${authorizationId}`)
    .set('Authorization', token);
};

export const fetchGithubRepos = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/github/repos`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const findGithubIssues = async (
  query: {
    url?: string;
    owner?: string;
    repo?: string;
  },
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/github/issues`)
    .query(query)
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

type SlackAuthorizationParams = {
  code: string;
  type: string;
  redirect_url?: string;
};

export const authorizeSlackIntegration = async (
  params: SlackAuthorizationParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/slack/oauth`)
    .query(params)
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

export const authorizeGoogleIntegration = async (
  query: GoogleAuthParams,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/google/oauth`)
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const authorizeGithubIntegration = async (
  query: Record<string, any>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/github/oauth`)
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const updateWidgetSettings = async (
  widgetSettingsParams: Partial<WidgetSettings>,
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

export const fetchAccountUsers = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/users`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchAccountUser = async (
  id: number,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/users/${id}`)
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

export const fetchNotes = async (
  query = {},
  token = getAccessToken()
): Promise<CustomerNote[]> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get('/api/notes')
    .query(query)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export type CustomerNotesListResponse = {
  data: Array<CustomerNote>;
};

export const fetchCustomerNotes = async (
  customerId: string,
  query = {},
  token = getAccessToken()
): Promise<CustomerNote[]> => {
  return fetchNotes({...query, customer_id: customerId}, token);
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

export const updateTag = async (
  id: string,
  tag: Partial<Tag>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/tags/${id}`)
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

export const fetchAllIssues = async (
  query = {},
  token = getAccessToken()
): Promise<Array<Issue>> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/issues`)
    .set('Authorization', token)
    .query(query)
    .then((res) => res.body.data);
};

export const fetchIssueById = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/issues/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createIssue = async (
  issue: Partial<Issue>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/issues`)
    .send({issue})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateIssue = async (
  id: string,
  issue: Partial<Issue>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/issues/${id}`)
    .send({issue})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteIssue = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/issues/${id}`)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const addCustomerIssue = async (
  customerId: string,
  issueId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/customers/${customerId}/issues`)
    .send({issue_id: issueId})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const removeCustomerIssue = async (
  customerId: string,
  issueId: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/customers/${customerId}/issues/${issueId}`)
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
): Promise<Array<BrowserSession>> => {
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

export const fetchPersonalApiKeys = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/personal_api_keys`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createPersonalApiKey = async (
  label: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/personal_api_keys`)
    .send({label})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deletePersonalApiKey = async (
  id: string,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/personal_api_keys/${id}`)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const getOnboardingStatus = async (
  token = getAccessToken()
): Promise<OnboardingStatus> => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/onboarding_status`)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const fetchLambdas = async (token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/lambdas`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const fetchLambda = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .get(`/api/lambdas/${id}`)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const createNewLambda = async (
  params: Partial<Lambda>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/lambdas`)
    .send({lambda: params})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const updateLambda = async (
  id: string,
  updates: Partial<Lambda>,
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .put(`/api/lambdas/${id}`)
    .send({lambda: updates})
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const deleteLambda = async (id: string, token = getAccessToken()) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .delete(`/api/lambdas/${id}`)
    .set('Authorization', token)
    .then((res) => res.body);
};

export const deployLambda = async (
  id: string,
  params = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/lambdas/${id}/deploy`)
    .send(params)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const invokeLambda = async (
  id: string,
  params = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/lambdas/${id}/invoke`)
    .send(params)
    .set('Authorization', token)
    .then((res) => res.body.data);
};

export const sendAdminNotification = async (
  params = {},
  token = getAccessToken()
) => {
  if (!token) {
    throw new Error('Invalid token!');
  }

  return request
    .post(`/api/admin/notifications`)
    .send(params)
    .set('Authorization', token)
    .then((res) => res.body.data);
};
