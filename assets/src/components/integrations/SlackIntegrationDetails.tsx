import React from 'react';
import {Box} from 'theme-ui';
import {Button, Divider, Paragraph, Text, Title} from '../common';
import * as API from '../../api';
import logger from '../../logger';

type Props = {};
type State = {authorization: any};

class SlackIntegrationDetails extends React.Component<Props, State> {
  state: State = {
    authorization: null,
  };

  async componentDidMount() {
    const auth = await API.fetchSlackAuthorization('reply');

    this.setState({authorization: auth});
  }

  render() {
    logger.debug('Slack authorization:', this.state.authorization);

    return (
      <Box p={4} sx={{maxWidth: 1080}}>
        <Box mb={5}>
          <Title level={4}>Reply from Slack</Title>

          <Paragraph>
            <Text>
              Reply to messages from your customers directly through Slack.
            </Text>
          </Paragraph>

          <Divider />

          <Button>Configure</Button>
        </Box>
      </Box>
    );
  }
}

export default SlackIntegrationDetails;
