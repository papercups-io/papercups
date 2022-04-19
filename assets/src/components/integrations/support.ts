import qs from 'query-string';
import {
  SLACK_CLIENT_ID,
  HUBSPOT_CLIENT_ID,
  INTERCOM_CLIENT_ID,
  isDev,
} from '../../config';
import {GoogleIntegrationParams} from '../../types';

export type IntegrationType = {
  key:
    | 'chat'
    | 'slack'
    | 'slack:sync'
    | 'mattermost'
    | 'gmail'
    | 'ses'
    | 'sheets'
    | 'github'
    | 'microsoft-teams'
    | 'whatsapp'
    | 'hubspot'
    | 'intercom'
    | 'salesforce'
    | 'jira'
    | 'zendesk'
    | 'twilio';
  integration: string;
  status: 'connected' | 'not_connected';
  createdAt?: string | null;
  authorizationId?: string | null;
  icon: string;
  description?: string;
  configurationUrl?: string;
  isPopular?: boolean;
};

export const getSlackRedirectUrl = () => {
  const origin = window.location.origin;

  return `${origin}/integrations/slack`;
};

export const getSlackAuthUrl = (
  type: 'reply' | 'support',
  inboxId?: string
) => {
  const scopes = [
    'incoming-webhook',
    'chat:write',
    'channels:history',
    'channels:manage',
    'channels:read',
    'chat:write.public',
    'chat:write.customize',
    'users:read',
    'users:read.email',
    'groups:history',
    'groups:read',
    'reactions:read',
    'files:read',
  ];
  const userScopes = [
    'channels:history',
    'groups:history',
    'chat:write',
    'reactions:read',
  ];
  const state = [type, inboxId].filter(Boolean).join(':');
  const q = {
    state,
    scope: scopes.join(' '),
    user_scope: userScopes.join(' '),
    client_id: SLACK_CLIENT_ID,
    redirect_uri: getSlackRedirectUrl(),
  };
  const query = qs.stringify(q);

  return `https://slack.com/oauth/v2/authorize?${query}`;
};

export const parseSlackAuthState = (state: string) => {
  const [type, inboxId] = state.split(':');

  return {type, inboxId};
};

export const getGoogleAuthUrl = ({
  client,
  type,
  inbox_id,
}: GoogleIntegrationParams) => {
  const origin = isDev ? 'http://localhost:4000' : window.location.origin;
  const q = qs.stringify({
    client,
    type,
    inbox_id,
    state: [type, inbox_id].filter(Boolean).join(':'),
  });

  return `${origin}/google/auth?${q}`;
};

// Both Google and Slack auth states are handled the same for now
export const parseGoogleAuthState = parseSlackAuthState;

export const getHubspotRedirectUrl = () => {
  const origin = window.location.origin;

  return `${origin}/integrations/hubspot`;
};

export const getHubspotAuthUrl = () => {
  const redirect = getHubspotRedirectUrl();

  return `https://app.hubspot.com/oauth/authorize?client_id=${HUBSPOT_CLIENT_ID}&redirect_uri=${redirect}&scope=contacts%20content`;
};

export const getIntercomAuthUrl = () => {
  return `https://app.intercom.com/oauth?client_id=${INTERCOM_CLIENT_ID}`;
};
