import React from 'react';
import {Link} from 'react-router-dom';
import {Box} from 'theme-ui';
import {Channel, Socket, Presence} from 'phoenix';
import {Papercups} from '@papercups-io/chat-widget';
import {Alert, Button, Container, Paragraph, Text, Title} from '../common';
import * as API from '../../api';
import {SOCKET_URL} from '../../socket';
import {BrowserSession} from '../../types';
import SessionsTable from './SessionsTable';
import logger from '../../logger';

type Props = {};
type State = {
  loading: boolean;
  error: any;
  sessions: Array<BrowserSession>;
  sessionIds: Array<string>;
  sessionStatusMetadataById: {[id: string]: any};
  numSessions: number;
};

class SessionsOverview extends React.Component<Props, State> {
  socket: Socket | null = null;
  channel: Channel | null = null;

  state: State = {
    loading: true,
    error: null,
    sessions: [],
    sessionIds: [],
    sessionStatusMetadataById: {},
    numSessions: 0,
  };

  async componentDidMount() {
    try {
      const {id: accountId} = await API.fetchAccountInfo();
      const {count} = await API.countBrowserSessions({});

      this.setState({numSessions: count});
      this.connectToSocket(accountId);
    } catch (err) {
      logger.error('Error loading browser sessions!', err);

      this.setState({error: err, loading: false});
    }
  }

  componentWillUnmount() {
    if (this.channel && this.channel.leave) {
      this.channel.leave();
    }

    if (this.socket && this.socket.disconnect) {
      this.socket.disconnect();
    }
  }

  connectToSocket = async (accountId: string) => {
    this.socket = new Socket(SOCKET_URL, {
      params: {token: API.getAccessToken()},
    });

    this.socket.connect();
    this.channel = this.socket.channel(`events:admin:${accountId}:all`, {});

    this.channel
      .join()
      .receive('ok', (res: any) => {
        logger.debug('Joined event channel successfully!', res);
      })
      .receive('error', (err: any) => {
        logger.debug('Unable to join event channel!', err);
      });

    const presence = new Presence(this.channel);

    presence.onSync(() => {
      const records = presence.list().map(({metas}) => {
        const [info] = metas;

        return info;
      });
      const sessions = records.map((info) => {
        // Default to active=true for backwards compatibility
        const {session_id: sessionId, active = true, ts} = info;

        return {sessionId, active, ts};
      });
      const sessionIds = sessions.map((s) => s.sessionId);

      this.setState(
        {
          sessionIds: sessionIds,
          sessionStatusMetadataById: sessions.reduce(
            (acc, {sessionId, active, ts}) => {
              return {...acc, [sessionId]: {active, ts}};
            },
            {}
          ),
        },
        () => this.refreshBrowserSessions(sessionIds)
      );
    });
  };

  refreshBrowserSessions = async (sessionIds: Array<string>) => {
    if (!sessionIds || !sessionIds.length) {
      return this.setState({sessions: [], loading: false});
    }

    this.setState({loading: true});

    try {
      const sessions = await API.fetchBrowserSessions({sessionIds});

      this.setState({sessions, loading: false});
    } catch (err) {
      this.setState({error: err, loading: false});
    }
  };

  getSessionActiveMetadata = (sessionId: string): Record<string, any> => {
    const {sessionStatusMetadataById = {}} = this.state;

    return sessionStatusMetadataById[sessionId] || {};
  };

  render() {
    const {loading, numSessions, sessions = []} = this.state;
    const shouldRequireSetup =
      !loading && numSessions === 0 && sessions.length === 0;
    const formatted = sessions.map((s) => {
      return {...s, ...this.getSessionActiveMetadata(s.id)};
    });

    return (
      <Container>
        <Box mb={5}>
          <Title level={3}>Live Sessions (beta)</Title>

          <Box mb={4}>
            <Paragraph>
              View how vistors are interacting with your website.
            </Paragraph>

            {/* FIXME: need to figure out the best way to get people started */}
            {shouldRequireSetup ? (
              <Alert
                message={
                  <Text>
                    It looks like you haven't set up Storytime yet &mdash;{' '}
                    <Link to="/sessions/setup">click here</Link> to get started
                    with live sessions!
                  </Text>
                }
                type="warning"
                showIcon
              />
            ) : (
              <Alert
                message={
                  <Text>
                    This page is still a work in progress &mdash;{' '}
                    <Button
                      style={{padding: 0, height: 16}}
                      type="link"
                      onClick={Papercups.toggle}
                    >
                      let us know
                    </Button>{' '}
                    if you need any help getting started!
                  </Text>
                }
                type="info"
                showIcon
              />
            )}
          </Box>

          <SessionsTable loading={loading} sessions={formatted} />
        </Box>
      </Container>
    );
  }
}

export default SessionsOverview;
