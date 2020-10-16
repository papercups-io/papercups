import React from 'react';
import ReactDOM from 'react-dom';
import * as Sentry from '@sentry/react';
import LogRocket from 'logrocket';
import posthog from 'posthog-js';
import {Storytime} from '@papercups-io/storytime';
import './index.css';
import App from './App';
import {BASE_URL, isDev} from './config';
import {AuthProvider} from './components/auth/AuthProvider';
import * as serviceWorker from './serviceWorker';

const {
  REACT_APP_SENTRY_DSN,
  REACT_APP_LOGROCKET_ID,
  REACT_APP_STORYTIME_ENABLED,
  REACT_APP_ADMIN_ACCOUNT_ID = 'eb504736-0f20-4978-98ff-1a82ae60b266',
  REACT_APP_POSTHOG_TOKEN = 'cQo4wipp5ipWWXhTN8kTacBItgqo457yDRtzCMOr-Tw',
  REACT_APP_POSTHOG_API_HOST = 'https://app.posthog.com',
} = process.env;

if (REACT_APP_SENTRY_DSN && !isDev) {
  Sentry.init({dsn: REACT_APP_SENTRY_DSN});
}

if (REACT_APP_LOGROCKET_ID && !isDev) {
  LogRocket.init(REACT_APP_LOGROCKET_ID);
}

if (REACT_APP_STORYTIME_ENABLED) {
  Storytime.init({
    accountId: REACT_APP_ADMIN_ACCOUNT_ID,
    host: BASE_URL,
  });
}

if (REACT_APP_POSTHOG_TOKEN && !isDev) {
  posthog.init(REACT_APP_POSTHOG_TOKEN, {api_host: REACT_APP_POSTHOG_API_HOST});
}

ReactDOM.render(
  <AuthProvider>
    <App />
  </AuthProvider>,
  document.getElementById('root')
);

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
