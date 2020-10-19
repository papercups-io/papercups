import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {throttle} from 'lodash';
import {Channel, Socket} from 'phoenix';
import {Box, Flex} from 'theme-ui';
import {Replayer, ReplayerEvents} from 'rrweb';
import {Alert, Button, Paragraph, Text} from '../common';
import {ArrowLeftOutlined} from '../icons';
import {SOCKET_URL} from '../../socket';
import * as API from '../../api';
import logger from '../../logger';
import Spinner from '../Spinner';
import 'rrweb/dist/replay/rrweb-replay.min.css';

type Props = RouteComponentProps<{session: string}> & {};
type State = {
  loading: boolean;
  events: Array<any>;
  scale: number;
};

class LiveSessionViewer extends React.Component<Props, State> {
  socket: Socket | null = null;
  channel: Channel | null = null;
  replayer!: Replayer; // TODO: start off as null?
  container: any;

  state: State = {loading: true, events: [], scale: 1};

  // TODO: move a bunch of logic from here into separate functions
  async componentDidMount() {
    const {session: sessionId} = this.props.match.params;
    const {id: accountId} = await API.fetchAccountInfo();
    const root = document.getElementById('SessionPlayer') as Element;

    this.replayer = new Replayer([], {root: root, liveMode: true});

    this.replayer.on(ReplayerEvents.FullsnapshotRebuilded, () =>
      this.setIframeScale()
    );
    // TODO: do we want to scale the iframe here as well?
    this.replayer.on(ReplayerEvents.Resize, (...args: any) =>
      logger.debug(args)
    );

    // Socket connection below only necessary for live view
    this.socket = new Socket(SOCKET_URL, {
      params: {token: API.getAccessToken()},
    });

    this.socket.connect();
    // TODO: attempt refreshing access token?
    this.socket.onError(
      throttle(
        () =>
          logger.error('Error connecting to socket. Try refreshing the page.'),
        30 * 1000 // throttle every 30 secs
      )
    );

    this.channel = this.socket.channel(
      `events:admin:${accountId}:${sessionId}`,
      {}
    );

    this.channel.on('replay:event:emitted', (data) => {
      logger.log('New event emitted!', data);

      this.replayer.addEvent(data.event);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        logger.debug('Joined channel successfully', res);

        this.replayer.startLive();

        setTimeout(() => this.setIframeScale(), 100);
      })
      .receive('error', (err) => {
        logger.error('Unable to join', err);
      });

    window.addEventListener('resize', this.handleWindowResize);
    this.setState({loading: false});
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.handleWindowResize);

    if (this.replayer && this.replayer.pause) {
      this.replayer.pause();
    }

    if (this.channel && this.channel.leave) {
      logger.debug('Existing channel:', this.channel);

      this.channel.leave();
    }
  }

  setIframeScale = (cb?: () => void) => {
    if (!this.replayer || !this.replayer.iframe) {
      return 1;
    }

    const iframeWidth = Number(this.replayer.iframe.width);
    const iframeHeight = Number(this.replayer.iframe.height);
    const {
      clientWidth: containerWidth,
      clientHeight: containerHeight,
    } = this.container;
    const scaleX = containerWidth / iframeWidth;
    const scaleY = containerHeight / iframeHeight;
    logger.debug('Setting iframe scale:', {
      containerWidth,
      containerHeight,
      iframeWidth,
      iframeHeight,
      scaleX,
      scaleY,
    });
    const scale = scaleX < scaleY ? scaleX : scaleY;

    this.setState({scale: scale || 1}, cb);
  };

  handleWindowResize = () => {
    this.setIframeScale();
  };

  render() {
    const {loading, scale = 1} = this.state;

    return (
      <Box p={4}>
        <Box mb={4}>
          <Box mb={3} sx={{maxWidth: 960}}>
            <Paragraph>
              <Link to="/sessions">
                <Button icon={<ArrowLeftOutlined />}>
                  Back to all sessions
                </Button>
              </Link>
            </Paragraph>

            <Alert
              message={
                <Text>
                  Note: This is an experimental feature! Let us know if you
                  notice any issues or bugs.
                </Text>
              }
              type="warning"
              showIcon
            />
          </Box>
        </Box>

        <Flex className="rr-block" sx={{maxWidth: 960}}>
          <Box sx={{flex: 2, border: 'none'}}>
            {/* TODO: figure out the best way to style this */}
            {loading && (
              <Flex
                sx={{
                  flex: 1,
                  justifyContent: 'center',
                  alignItems: 'center',
                  height: '100%',
                }}
              >
                <Spinner size={40} />
              </Flex>
            )}
            <Box
              mx={2}
              style={{
                position: 'relative',
                height: 480,
                visibility: loading ? 'hidden' : 'visible',
              }}
              ref={(el) => (this.container = el)}
            >
              <div
                id="SessionPlayer"
                style={{
                  transform: `scale(${scale})`,
                  transformOrigin: 'top left',
                }}
              ></div>
            </Box>
          </Box>
        </Flex>
      </Box>
    );
  }
}

export default LiveSessionViewer;
