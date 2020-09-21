import React from 'react';
import {Box} from 'theme-ui';
import qs from 'query-string';
import SyntaxHighlighter from 'react-syntax-highlighter';
import {atomOneLight} from 'react-syntax-highlighter/dist/esm/styles/hljs';
import {notification, Divider} from './components/common';
import {isHostedProd} from './config';

const noop = () => {};

type Level = 'debug' | 'log' | 'info' | 'warn' | 'error';

type Options = {
  debugModeEnabled?: boolean;
  logUnhandledErrors?: boolean;
  callback?: (level: Level, ...args: any) => void;
};

export class Logger {
  debugModeEnabled: boolean;
  callback: (level: Level, ...args: any) => void;

  constructor(opts: Options) {
    const {
      debugModeEnabled = false,
      logUnhandledErrors = false,
      callback = noop,
    } = opts;

    this.debugModeEnabled = !!debugModeEnabled;
    this.callback = callback;

    if (logUnhandledErrors) {
      this.listen();
    }
  }

  debug(...args: any) {
    if (!this.debugModeEnabled) {
      return;
    }

    console.debug(...args);
    this.callback('debug', ...args);
  }

  log(...args: any) {
    if (!this.debugModeEnabled) {
      return;
    }

    console.log(...args);
    this.callback('log', ...args);
  }

  info(...args: any) {
    console.info(...args);
    this.callback('info', ...args);
  }

  warn(...args: any) {
    console.warn(...args);
    this.callback('warn', ...args);
  }

  error(...args: any) {
    console.error(...args);
    this.callback('error', ...args);
  }

  listen() {
    window.onerror = (msg, url, lineNo, columnNo, error) => {
      const stack = error?.stack || '';
      const line = stack.split('\n')[1].trim();
      this.error(msg, line);
    };

    window.addEventListener('unhandledrejection', (event) => {
      const {message, stack} = event.reason;
      const line = stack.split('\n')[1].trim();
      this.error(message, line);
    });
  }
}

const stringify = (data: any) => {
  if (data instanceof Error) {
    return data.toString();
  } else if (typeof data === 'object') {
    return (
      <SyntaxHighlighter
        language="javascript"
        style={atomOneLight}
        customStyle={{maxHeight: 232, fontSize: 12, overflowY: 'scroll'}}
      >
        {JSON.stringify(data, null, 2)}
      </SyntaxHighlighter>
    );
  }

  return data;
};

const {debug = 0} = qs.parse(window?.location?.search || '');
const forceDebugModeEnabled =
  !!Number(debug) || !!Number(process.env.REACT_APP_DEBUG_MODE_ENABLED);

const callback = (type: Level, ...args: any) => {
  const description = args.map((arg: any, idx: number) => {
    const isLast = idx === args.length - 1;

    return (
      <Box key={idx}>
        {stringify(arg)}
        {isLast ? null : <Divider style={{margin: '8px 0'}} />}
      </Box>
    );
  });

  switch (type) {
    case 'error':
      return notification.error({
        message: 'Something went wrong!',
        duration: null,
        description,
      });
    case 'warn':
      return notification.warn({
        message: 'Warning',
        duration: null,
        description,
      });
    case 'info':
      return notification.info({
        message: 'Debug info',
        duration: null,
        description,
      });
    case 'log':
    case 'debug':
    default:
      return notification.open({
        message: 'Debug',
        duration: null,
        description,
      });
  }
};

const logger = new Logger({
  debugModeEnabled: !isHostedProd || forceDebugModeEnabled,
  logUnhandledErrors: !isHostedProd || forceDebugModeEnabled,
  callback: forceDebugModeEnabled ? callback : noop,
});

export default logger;
