import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Replayer} from 'rrweb';
import qs from 'query-string';
import {Alert, Button, Paragraph, Text} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import Spinner from '../Spinner';
import RrWebPlayer from './RrWebPlayer';
import 'rrweb/dist/replay/rrweb-replay.min.css';

type Props = RouteComponentProps<{session: string}> & {};
type State = {
  loading: boolean;
  events: Array<any>;
  scale: number;
  showExperimentalPlayer?: boolean;
};

class SessionReplay extends React.Component<Props, State> {
  replayer!: Replayer;
  container: any;

  state: State = {
    loading: true,
    events: [],
    scale: 1,
    showExperimentalPlayer: false,
  };

  // TODO: move a bunch of logic from here into separate functions
  async componentDidMount() {
    const {session: sessionId} = this.props.match.params;
    const {search = ''} = this.props.location;
    const {player = '0'} = qs.parse(search);
    const session = await API.fetchBrowserSession(sessionId);

    logger.info('Session:', session);

    const {browser_replay_events = []} = session;
    const events = browser_replay_events
      .map((e: any) => e.event)
      .sort((a: any, b: any) => a.timestamp - b.timestamp);
    const showExperimentalPlayer = !!Number(player);

    this.setState(
      {
        events,
        loading: false,
        showExperimentalPlayer,
      },
      () => showExperimentalPlayer && this.setUpPlayer(events)
    );
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.handleWindowResize);
  }

  setUpPlayer = (events: Array<any>) => {
    if (events && events.length < 2) {
      return logger.error('Must have at least 2 events!');
    }

    const root = document.getElementById('SessionPlayer') as Element;

    this.replayer = new Replayer(events, {
      root: root,
      skipInactive: true,
    });

    this.replayer.play();
    setTimeout(() => this.setIframeScale(), 0);

    window.addEventListener('resize', this.handleWindowResize);
  };

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
    const {
      loading,
      events = [],
      scale = 1,
      showExperimentalPlayer = false,
    } = this.state;

    if (loading) {
      return (
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
      );
    }

    return (
      <Box p={4}>
        <Box mb={3} sx={{maxWidth: 960}}>
          <Paragraph>
            <Link to="/sessions">
              <Button icon={<ArrowLeftOutlined />}>
                Back to browser sessions
              </Button>
            </Link>
          </Paragraph>

          <Alert
            message={
              <Text>
                Note: This is an experimental feature! Let us know if you see
                any issues.
              </Text>
            }
            type="warning"
            showIcon
          />
        </Box>

        <Flex className="rr-block">
          <Box sx={{flex: 2, border: 'none'}}>
            {showExperimentalPlayer ? (
              // TODO: figure out the best way to style this
              // TODO: container needs to be loaded first???
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
            ) : (
              <RrWebPlayer events={events} />
            )}
          </Box>
        </Flex>
      </Box>
    );
  }
}

export default SessionReplay;
