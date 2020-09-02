import React from 'react';
import ReactDOM from 'react-dom';
import * as Sentry from '@sentry/react';
import LogRocket from 'logrocket';
import posthog from 'posthog-js';
import './index.css';
import App from './App';
import {AuthProvider} from './components/auth/AuthProvider';
import * as serviceWorker from './serviceWorker';

const {
  REACT_APP_SENTRY_DSN,
  REACT_APP_LOGROCKET_ID,
  REACT_APP_POSTHOG_TOKEN,
} = process.env;

if (REACT_APP_SENTRY_DSN) {
  Sentry.init({dsn: REACT_APP_SENTRY_DSN});
}

if (REACT_APP_LOGROCKET_ID) {
  LogRocket.init(REACT_APP_LOGROCKET_ID);
}

if (REACT_APP_POSTHOG_TOKEN) {
  posthog.init(REACT_APP_POSTHOG_TOKEN, {api_host: 'https://app.posthog.com'});
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
