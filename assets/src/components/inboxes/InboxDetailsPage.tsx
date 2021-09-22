import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {
  Button,
  Card,
  colors,
  Container,
  Divider,
  Tag,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import Spinner from '../Spinner';
import {Inbox} from '../../types';
import {formatServerError} from '../../utils';
import InboxIntegrations from './InboxIntegrations';
import InboxForwardingAddresses from './InboxForwardingAddresses';
import MailOutlined from '@ant-design/icons/MailOutlined';

type Props = RouteComponentProps<{inbox_id: string}>;
type State = {
  status: 'loading' | 'success' | 'error';
  inbox: Inbox | null;
  error: any;
};

class InboxDetailsPage extends React.Component<Props, State> {
  state: State = {
    status: 'loading',
    inbox: null,
    error: null,
  };

  async componentDidMount() {
    try {
      const {inbox_id: inboxId} = this.props.match.params;
      const inbox = await API.fetchInbox(inboxId);

      this.setState({inbox, status: 'success'});
    } catch (error) {
      logger.error(error);

      this.setState({status: 'error', error: formatServerError(error)});
    }
  }

  render() {
    const {status, inbox, error} = this.state;

    if (status === 'loading') {
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

    if (error || !inbox) {
      return null;
    }

    const {id: inboxId, name, description, is_primary: isPrimary} = inbox;

    return (
      <Container sx={{maxWidth: 960}}>
        <Box mb={4}>
          <Link to="/inboxes">
            <Button icon={<ArrowLeftOutlined />}>Back to inboxes</Button>
          </Link>
        </Box>

        <Box mb={4}>
          <Card sx={{p: 3}}>
            <Flex sx={{alignItems: 'center'}} mb={2}>
              <Title level={3} style={{margin: 0}}>
                {name}
              </Title>
              {isPrimary && (
                <Box mx={3}>
                  <Tag color={colors.primary}>Primary</Tag>
                </Box>
              )}
            </Flex>

            <Flex
              sx={{justifyContent: 'space-between', alignItems: 'baseline'}}
            >
              <Text>{description || 'No description.'}</Text>

              <Link to={`/inboxes/${inboxId}/conversations`}>
                <Button icon={<MailOutlined />}>View conversations</Button>
              </Link>
            </Flex>
          </Card>
        </Box>

        <Divider />

        <Box mb={4}>
          <InboxIntegrations inbox={inbox} />
        </Box>

        <Divider />

        <Box mb={4}>
          <InboxForwardingAddresses inbox={inbox} />
        </Box>
      </Container>
    );
  }
}

export default InboxDetailsPage;
