import qs from 'query-string';
import {SLACK_CLIENT_ID, isDev} from '../../config';
import {GoogleIntegrationParams} from '../../types';

export type IntegrationType = {
  key:
    | 'slack'
    | 'slack:sync'
    | 'mattermost'
    | 'gmail'
    | 'sheets'
    | 'github'
    | 'microsoft-teams'
    | 'whatsapp'
    | 'twilio';
  integration: string;
  status: 'connected' | 'not_connected';
  created_at?: string | null;
  authorization_id: string | null;
  icon: string;
  description?: string;
};

export const getSlackRedirectUrl = () => {
  const origin = window.location.origin;

  return `${origin}/integrations/slack`;
};

export const getSlackAuthUrl = (type = 'reply') => {
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
  ];
  const userScopes = [
    'channels:history',
    'groups:history',
    'chat:write',
    'reactions:read',
  ];
  const q = {
    state: type,
    scope: scopes.join(' '),
    user_scope: userScopes.join(' '),
    client_id: SLACK_CLIENT_ID,
    redirect_uri: getSlackRedirectUrl(),
  };
  const query = qs.stringify(q);

  return `https://slack.com/oauth/v2/authorize?${query}`;
};

export const getGoogleAuthUrl = ({client, type}: GoogleIntegrationParams) => {
  const origin = isDev ? 'http://localhost:4000' : window.location.origin;

  return `${origin}/google/auth?client=${client}&type=${type}`;
};
