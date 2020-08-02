export const SOCKET_URL =
  window.location.hostname === 'localhost'
    ? 'ws://localhost:4000/socket'
    : '/socket';
