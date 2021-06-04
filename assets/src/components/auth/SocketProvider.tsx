import React, {useContext} from 'react';
import {Socket} from 'phoenix';
import {throttle} from 'lodash';
import {SOCKET_URL} from '../../socket';
import * as API from '../../api';
import logger from '../../logger';
import {noop} from '../../utils';

export const SocketContext = React.createContext<{
  socket: Socket;
  hasConnectionError?: boolean;
}>({
  socket: new Socket(SOCKET_URL),
  hasConnectionError: false,
});

export const useSocket = () => useContext(SocketContext);

type Props = {
  url?: string;
  options?: any;
  refresh: (token: string) => Promise<void>;
} & React.PropsWithChildren<{}>;

type State = {
  socket: Socket;
  history: Array<Socket>;
};

export class SocketProvider extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    const {url = SOCKET_URL} = props;
    const socket = new Socket(url, {params: {token: API.getAccessToken()}});

    this.state = {
      socket,
      history: [socket],
    };
  }

  componentDidMount() {
    this.connect();
  }

  componentWillUnmount() {
    this.disconnect();
  }

  createNewSocket = () => {
    const {url = SOCKET_URL} = this.props;

    return new Socket(url, {params: {token: API.getAccessToken()}});
  };

  connect = () => {
    const {socket} = this.state;

    socket.connect();

    socket.onOpen(() => {
      logger.debug(`Successfully connected to socket!`, socket);
    });

    socket.onClose(() => {
      logger.debug(`Socket successfully closed!`, socket);
    });

    socket.onError(
      throttle(() => {
        logger.error(
          `Error connecting to socket. Try refreshing the page.`,
          socket
        );

        this.reconnect();
      }, 10000)
    );
  };

  reconnect = () => {
    this.disconnect(async () => {
      const token = API.getRefreshToken();

      if (!token) {
        // Attempt connect again
        return this.connect();
      }

      await this.props.refresh(token);

      const socket = this.createNewSocket();

      this.setState({socket, history: [socket, ...this.state.history]}, () =>
        this.connect()
      );
    });
  };

  disconnect = (cb = noop) => {
    const {socket} = this.state;

    socket.disconnect(cb);
  };

  render() {
    return (
      <SocketContext.Provider value={{socket: this.state.socket}}>
        {this.props.children}
      </SocketContext.Provider>
    );
  }
}

export default SocketProvider;
