import React from 'react';
import ReactDOM from 'react-dom';
import * as Sentry from '@sentry/react';
import LogRocket from 'logrocket';
import posthog from 'posthog-js';
import './index.css';
import App from './App';
import {isDev} from './config';
import {AuthProvider} from './components/auth/AuthProvider';
import * as Storytime from './lib/storytime';
import * as serviceWorker from './serviceWorker';

Storytime.initialize('TEST_ACCOUNT_ID', 'TEST_CUSTOMER_ID');

const {
  REACT_APP_SENTRY_DSN,
  REACT_APP_LOGROCKET_ID,
  REACT_APP_POSTHOG_TOKEN = 'cQo4wipp5ipWWXhTN8kTacBItgqo457yDRtzCMOr-Tw',
  REACT_APP_POSTHOG_API_HOST = 'https://app.posthog.com',
} = process.env;

if (REACT_APP_SENTRY_DSN && !isDev) {
  Sentry.init({dsn: REACT_APP_SENTRY_DSN});
}

if (REACT_APP_LOGROCKET_ID && !isDev) {
  LogRocket.init(REACT_APP_LOGROCKET_ID);
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
