import React from 'react';
import {Box} from 'theme-ui';
import {Channel, Socket, Presence} from 'phoenix';
import {Alert, Paragraph, Text, Title} from '../common';
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
};

class SessionsOverview extends React.Component<Props, State> {
  socket: Socket | null = null;
  channel: Channel | null = null;

  state: State = {
    loading: true,
    error: null,
    sessions: [],
    sessionIds: [],
  };

  async componentDidMount() {
    try {
      const {id: accountId} = await API.fetchAccountInfo();

      this.connectToSocket(accountId);
    } catch (err) {
      logger.error('Error loading browser sessions!', err);

      this.setState({error: err, loading: false});
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
      const sessionIds = presence
        .list()
        .map(({metas}) => {
          const [info] = metas;

          return info.session_id;
        })
        .filter((sessionId) => !!sessionId);

      this.setState(
        {
          sessionIds: sessionIds,
        },
        () => this.refreshBrowserSessions(sessionIds)
      );
    });
  };

  refreshBrowserSessions = async (sessionIds: Array<string>) => {
    this.setState({loading: true});

    try {
      const sessions = await API.fetchBrowserSessions(sessionIds);

      this.setState({sessions, loading: false});
    } catch (err) {
      this.setState({error: err, loading: false});
    }
  };

  render() {
    const {loading, sessions = []} = this.state;

    return (
      <Box p={4}>
        <Box mb={5}>
          <Title level={3}>Live Sessions (beta)</Title>

          <Box mb={4}>
            <Paragraph>
              View how vistors are interacting with your website.
            </Paragraph>

            <Alert
              message={
                <Text>
                  This page is still a work in progress &mdash; more features
                  coming soon!
                </Text>
              }
              type="info"
              showIcon
            />
          </Box>

          <SessionsTable loading={loading} sessions={sessions} />
        </Box>
      </Box>
    );
  }
}

export default SessionsOverview;
