import * as Sentry from '@sentry/react';
import LogRocket from 'logrocket';
import posthog from 'posthog-js';
import {isDev} from './config';

const {
  REACT_APP_SENTRY_DSN,
  REACT_APP_LOGROCKET_ID,
  REACT_APP_POSTHOG_TOKEN = 'cQo4wipp5ipWWXhTN8kTacBItgqo457yDRtzCMOr-Tw',
  REACT_APP_POSTHOG_API_HOST = 'https://app.posthog.com',
} = process.env;

export const isSentryEnabled = REACT_APP_SENTRY_DSN && !isDev;
export const isLogRocketEnabled = REACT_APP_LOGROCKET_ID && !isDev;
export const isPostHogEnabled = REACT_APP_POSTHOG_TOKEN && !isDev;

export const init = () => {
  if (isSentryEnabled) {
    Sentry.init({dsn: REACT_APP_SENTRY_DSN});
  }

  if (isLogRocketEnabled && REACT_APP_LOGROCKET_ID) {
    LogRocket.init(REACT_APP_LOGROCKET_ID);
  }

  if (isPostHogEnabled) {
    posthog.init(REACT_APP_POSTHOG_TOKEN, {
      api_host: REACT_APP_POSTHOG_API_HOST,
    });
  }
};

export const identify = (id: any, email: string) => {
  if (isSentryEnabled) {
    Sentry.setUser({id, email});
  }

  if (isLogRocketEnabled) {
    LogRocket.identify(id, {email});
  }

  if (isPostHogEnabled) {
    posthog.identify(id);
    posthog.people && posthog.people.set({email});
  }
};

export default {
  init,
  identify,
};
