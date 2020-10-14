import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Channel, Socket} from 'phoenix';
import {Box, Flex} from 'theme-ui';
import {Replayer} from 'rrweb';
import {Title} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import 'rrweb/dist/replay/rrweb-replay.min.css';

type Props = RouteComponentProps<{session: string}> & {};
type State = {
  loading: boolean;
  events: Array<any>;
  scale: number;
};

class SessionReplay extends React.Component<Props, State> {
  socket: Socket | null = null;
  channel: Channel | null = null;
  replayer!: Replayer;
  container: any;

  state: State = {loading: true, events: [], scale: 1};

  // TODO: move a bunch of logic from here into separate functions
  async componentDidMount() {
    const {session: sessionId} = this.props.match.params;
    const session = await API.fetchBrowserSession(sessionId);

    logger.info('Session:', session);

    const root = document.getElementById('SessionPlayer') as Element;
    const {browser_replay_events = []} = session;
    const events = browser_replay_events
      .map((e: any) => e.event)
      .sort((a: any, b: any) => a.timestamp - b.timestamp);

    this.setState({events, loading: false});

    if (events && events.length < 2) {
      return logger.error('Must have at least 2 events!');
    }

    this.replayer = new Replayer(events, {
      root: root,
      skipInactive: true,
    });

    this.replayer.play();
    setTimeout(() => this.setIframeScale(), 0);

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
          <Title level={3}>Session Replay</Title>
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

export default SessionReplay;
