import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Alert, Paragraph, Text, Title} from '../common';
import * as API from '../../api';
import {BrowserSession} from '../../types';
import Spinner from '../Spinner';
import SessionsTable from './SessionsTable';
import logger from '../../logger';

type Props = {};
type State = {
  loading: boolean;
  sessions: Array<BrowserSession>;
};

class SessionsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    sessions: [],
  };

  async componentDidMount() {
    try {
      const sessions = await API.fetchBrowserSessions();

      this.setState({sessions, loading: false});
    } catch (err) {
      logger.error('Error loading browser sessions!', err);

      this.setState({loading: false});
    }
  }

  render() {
    const {loading, sessions = []} = this.state;

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
        <Box mb={5}>
          <Title level={3}>Browser Sessions (beta)</Title>

          <Box mb={4}>
            <Paragraph>
              View how recent vistors have interacted with your website.
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

          <SessionsTable sessions={sessions} />
        </Box>
      </Box>
    );
  }
}

export default SessionsOverview;
