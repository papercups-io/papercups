import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {colors, Button, Paragraph, Table, Tag, Text, Title} from '../common';
import Spinner from '../Spinner';
import {SLACK_CLIENT_ID} from '../../config';
import * as API from '../../api';

type IntegrationType = {
  key: 'slack' | 'gmail';
  integration: string;
  status: 'connected' | 'not_connected';
  created_at?: string | null;
  icon: string;
};

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  integrations: Array<IntegrationType>;
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    integrations: [],
  };

  async componentDidMount() {
    try {
      const {match, location} = this.props;
      const {search} = location;
      const {type} = match.params;

      if (type) {
        await this.handleIntegrationType(type, search);
      }

      const integrations = await Promise.all([
        this.fetchSlackIntegration(),
        this.fetchGmailIntegration(),
      ]);

      this.setState({integrations, loading: false});
    } catch (err) {
      console.log('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

  fetchSlackIntegration = async (): Promise<IntegrationType> => {
    const auth = await API.fetchSlackAuthorization();

    return {
      key: 'slack',
      integration: 'Slack',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      icon: '/slack.svg',
    };
  };

  fetchGmailIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'gmail',
      integration: 'Gmail',
      status: 'not_connected',
      created_at: null,
      icon: '/gmail.svg',
    };
  };

  handleIntegrationType = (type: string, query: string = '') => {
    const q = qs.parse(query);

    switch (type) {
      case 'slack':
        const code = String(q.code);

        return API.authorizeSlackIntegration(code).catch((err) =>
          console.log('Failed to authorize Slack:', err)
        );
      default:
        return null;
    }
  };

  render() {
    const {loading, integrations = []} = this.state;
    const columns = [
      {
        title: 'Integration',
        dataIndex: 'integration',
        key: 'integration',
        render: (value: string, record: any) => {
          const {icon} = record;

          return (
            <Flex sx={{alignItems: 'center'}}>
              <img src={icon} alt={value} style={{height: 20}} />
              <Text strong style={{marginLeft: 8}}>
                {value}
              </Text>
            </Flex>
          );
        },
      },
      {
        title: 'Status',
        dataIndex: 'status',
        key: 'status',
        render: (value: string) => {
          return value === 'connected' ? (
            <Tag color={colors.green}>Connected</Tag>
          ) : (
            <Tag>Not connected</Tag>
          );
        },
      },
      {
        title: 'Connected since',
        dataIndex: 'created_at',
        key: 'created_at',
        render: (value: string) => {
          if (!value) {
            return '--';
          }

          return dayjs(value).format('MMMM DD, YYYY');
        },
      },
      {
        title: 'Action',
        dataIndex: 'action',
        key: 'action',
        render: (action: any, record: any) => {
          const {key, status} = record;
          const isConnected = status === 'connected';
          // NB: when testing locally, update `origin` to an ngrok url
          // pointing at localhost:4000 (or wherever your server is running)
          const origin = window.location.origin;
          const redirect = `${origin}/integrations/slack`;
          const q = {
            scope: 'incoming-webhook chat:write channels:history',
            user_scope: 'channels:history',
            client_id: SLACK_CLIENT_ID,
            redirect_uri: redirect,
          };
          const query = qs.stringify(q);

          switch (key) {
            case 'slack':
              return (
                <a href={`https://slack.com/oauth/v2/authorize?${query}`}>
                  <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
                </a>
              );
            default:
              return <Button disabled>Coming soon!</Button>;
          }
        },
      },
    ];

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
          <Title level={4}>Integrations</Title>

          <Paragraph>
            <Text>
              Connect with your favorite apps{' '}
              <span role="img" aria-label="apps">
                🚀
              </span>
            </Text>
          </Paragraph>

          <Box my={4}>
            <Table dataSource={integrations} columns={columns} />;
          </Box>
        </Box>
      </Box>
    );
  }
}

export default IntegrationsOverview;
