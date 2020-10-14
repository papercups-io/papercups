import {Socket} from 'phoenix';
import {record} from 'rrweb';
import request from 'superagent';
import {SOCKET_URL} from '../socket';

const socket = new Socket(SOCKET_URL);
// TODO: figure out a better way to prevent recording on certain pages
// const blocklist: Array<string> = ['/player', '/sessions'];
const blocklist: Array<string> = [];

socket.connect();

const shouldEmitEvent = (pathName: string) => {
  return blocklist.every((p) => pathName.indexOf(p) === -1);
};

export const createBrowserSession = async (accountId: string) => {
  return request
    .post(`/api/browser_sessions`)
    .send({
      browser_session: {
        account_id: accountId,
        started_at: new Date(),
      },
    })
    .then((res) => res.body.data);
};

// TODO: use public key to match account, then use secret key on server
export const initialize = async (
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
  const {id: sessionId} = await createBrowserSession(accountId);
  // const sessionId = '15f2836c-6d88-4719-9528-d8db45ebb9bc';
  console.log('Session!', sessionId);
  const channel = socket.channel(`events:${accountId}:${sessionId}`, {
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
