import React from 'react';
import ReactDOM from 'react-dom';
import * as Sentry from '@sentry/react';
import LogRocket from 'logrocket';
import './index.css';
import App from './App';
import {AuthProvider} from './components/auth/AuthProvider';
import * as serviceWorker from './serviceWorker';

if (process.env.REACT_APP_SENTRY_DSN) {
  Sentry.init({dsn: process.env.REACT_APP_SENTRY_DSN});
}

if (process.env.REACT_APP_LOGROCKET_ID) {
  LogRocket.init('uda6eb/papercups');
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
