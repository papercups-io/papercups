import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {throttle} from 'lodash';
import {Channel, Socket} from 'phoenix';
import {Box, Flex} from 'theme-ui';
import {Replayer} from 'rrweb';
import {Title} from '../common';
import {SOCKET_URL} from '../../socket';
import * as API from '../../api';
import logger from '../../logger';
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
    const session = await API.fetchBrowserSession(sessionId);

    logger.info('Session:', {session});

    const root = document.getElementById('SessionPlayer') as Element;
    const {account_id: accountId, browser_replay_events = []} = session;
    const events = browser_replay_events
      .map((e: any) => e.event)
      .sort((a: any, b: any) => a.timestamp - b.timestamp);

    this.setState({events, loading: false});
    this.replayer = new Replayer([], {root: root, liveMode: true});

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

        // const [start] = events;
        // events.forEach((event: any) => this.replayer.addEvent(event));
        // this.replayer.startLive(start?.timestamp ?? null);
        this.replayer.startLive();

        setTimeout(() => this.setIframeScale(), 100);
      })
      .receive('error', (err) => {
        logger.error('Unable to join', err);
      });

    window.addEventListener('resize', this.handleWindowResize);
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
    logger.debug({
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
          <Title level={3}>Live view</Title>
        </Box>

        <Flex>
          <Box sx={{flex: 2, border: 'none'}}>
            {/* TODO: figure out the best way to style this */}
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
