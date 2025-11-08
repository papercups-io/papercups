import React from 'react';
import {createRoot} from 'react-dom/client';
import './index.css';
import App from './App';
import analytics from './analytics';
import {AuthProvider} from './components/auth/AuthProvider';
import * as serviceWorker from './serviceWorker';

analytics.init();

const container = document.getElementById('root');
const root = createRoot(container!);
root.render(
  <AuthProvider>
    <App />
  </AuthProvider>
);

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
