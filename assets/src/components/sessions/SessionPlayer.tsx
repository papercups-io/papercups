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

class LiveViewPage extends React.Component<Props, State> {
  socket: Socket | null = null;
  channel: Channel | null = null;
  replayer!: Replayer;
  container: any;

  state: State = {loading: true, events: [], scale: 1};

  // TODO: move a bunch of logic from here into separate functions
  async componentDidMount() {
    // const {session: sessionId} = this.props.match.params;
    // const session = await API.fetchBrowserSession(sessionId);

    // logger.debug('Session:', session);

    const events: Array<any> = []; // TODO: fetch previous events from server?
    const root = document.getElementById('SessionPlayer') as Element;

    this.replayer = new Replayer(events, {root: root, liveMode: true});

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

    this.channel = this.socket.channel(`event:${'TEST_ACCOUNT_ID'}`, {});

    this.channel.on('replay:event:emitted', (data) => {
      logger.debug('New event emitted!', data);

      this.replayer.addEvent(data.event);
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        logger.debug('Joined channel successfully', res);

        // const session = await this.fetchBrowserSesssion(sessionId);
        // const {browser_replay_events = []} = session;
        const events: Array<any> = []; // browser_replay_events.map((e: any) => e.event);

        events.forEach((event: any) => this.replayer.addEvent(event));

        this.replayer.startLive();
        setTimeout(() => this.setIframeScale(), 0);

        this.setState({loading: false});
      })
      .receive('error', (err) => {
        logger.error('Unable to join', err);
      });

    window.addEventListener('resize', this.handleWindowResize);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.handleWindowResize);
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
          <Title>Replayer</Title>
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

export default LiveViewPage;
