import {Socket} from 'phoenix';
import {record} from 'rrweb';
import {SOCKET_URL} from '../socket';

const socket = new Socket(SOCKET_URL);
const blocklist: Array<string> = ['/player'];

socket.connect();

const shouldEmitEvent = (pathName: string) => {
  return blocklist.every((p) => pathName.indexOf(p) === -1);
};

// TODO: use public key to match account, then use secret key on server
export const initialize = (
  accountId: string,
  customerId: string,
  publicKey?: string
) => {
  // TODO: figure out a better pattern for this
  if (!socket.isConnected()) {
    socket.connect();
  }

  socket.onError(console.error);

  // TODO: create a session token every time

  const channel = socket.channel(`event:${accountId}`, {
    customerId,
  });

  channel
    .join()
    .receive('ok', (res) => {
      // Start recording session
      console.log('Recording!', {accountId, customerId});

      record({
        emit(event) {
          const pathName = window.location.pathname;

          // TODO: just emit everything until bug is fixed?
          if (shouldEmitEvent(pathName)) {
            channel.push('replay:event:emitted', {
              event,
              customer_id: customerId,
            });
          }
        },
      });

      window.addEventListener('beforeunload', (e) => {
        // TODO: end session
      });
    })
    .receive('error', (err) => {
      // TODO: handle error
    });
};
