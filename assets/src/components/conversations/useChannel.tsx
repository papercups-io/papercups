import React from 'react';
import {Channel} from 'phoenix';

import logger from '../../logger';
import {useSocket} from '../auth/SocketProvider';
import {noop} from '../../utils';

export const useChannel = (
  channel: string,
  {
    data = {},
    handlers = {},
    onSuccess = noop,
    onError = noop,
  }: {
    data?: any;
    handlers?: {[event: string]: (data?: any) => void};
    onSuccess?: (data?: any) => void;
    onError?: (error?: any) => void;
  }
) => {
  const {socket} = useSocket();
  const ref = React.useRef<Channel>(socket.channel(channel, data));

  React.useEffect(() => {
    ref.current = socket.channel(channel, data);

    Object.keys(handlers).forEach((event) => {
      const fn = handlers[event];

      ref.current.on(event, fn);
    });

    ref.current
      .join()
      .receive('ok', (res) => {
        logger.debug(`Successfully joined channel ${channel}:`, res);
        onSuccess && onSuccess(res);
      })
      .receive('error', (err) => {
        logger.error(`Unable to join channel ${channel}:`, err);
        onError && onError(err);
      });

    return () => {
      ref.current.leave();
    };
    // eslint-disable-next-line
  }, [channel]);

  return ref.current;
};

export default useChannel;
