import {Socket} from 'phoenix';

const url =
  window.location.hostname === 'localhost'
    ? 'ws://localhost:4000/socket'
    : '/socket';

export const socket = new Socket(url);
