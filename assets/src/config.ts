export const isDev = Boolean(
  window.location.hostname === 'localhost' ||
    // [::1] is the IPv6 localhost address.
    window.location.hostname === '[::1]' ||
    // 127.0.0.0/8 are considered localhost for IPv4.
    window.location.hostname.match(
      /^127(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$/
    )
);

export const isHostedProd = window.location.hostname === 'app.papercups.io';

export const isEuEdition =
  process.env.REACT_APP_EU_EDITION === 'true' ||
  process.env.REACT_APP_EU_EDITION === '1';

export const REACT_URL = process.env.REACT_APP_URL || 'app.papercups.io';

export const BASE_URL = isDev
  ? 'http://localhost:4000'
  : `https://${REACT_URL}`;

// In the dev environment, we use port 3000 and proxy API requests to 4000
export const FRONTEND_BASE_URL = isDev ? 'http://localhost:3000' : BASE_URL;

// Defaults to Papercups client ID (it's ok for this value to be public)
export const SLACK_CLIENT_ID =
  process.env.REACT_APP_SLACK_CLIENT_ID || '1192316529232.1250363411891';
