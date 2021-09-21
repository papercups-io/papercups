import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';

import {colors, Button, Table, Tag, Text, Title} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';
import {IntegrationType} from '../integrations/support';
import {isEuEdition} from '../../config';
import {SettingOutlined} from '../icons';
import {Inbox} from '../../types';

const InboxIntegrationsTable = ({
  loading,
  inboxId,
  integrations,
}: {
  loading?: boolean;
  inboxId: string;
  integrations: Array<IntegrationType>;
}) => {
  const columns = [
    {
      title: 'Name',
      dataIndex: 'integration',
      key: 'integration',
      render: (value: string, record: IntegrationType) => {
        const {icon, description} = record;

        return (
          <Box>
            <Flex sx={{alignItems: 'center'}}>
              <img src={icon} alt={value} style={{height: 20}} />
              <Text strong style={{marginLeft: 8}}>
                {value}
              </Text>
            </Flex>
            {description && (
              <Box mt={2} sx={{maxWidth: 480}}>
                <Text type="secondary">{description}</Text>
              </Box>
            )}
          </Box>
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
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (action: any, record: IntegrationType) => {
        const {key} = record;

        switch (key) {
          case 'chat':
            return (
              // TODO: update path
              <Link to={`/inboxes/${inboxId}/chat-widget`}>
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'slack':
            return (
              <Link to={`/inboxes/${inboxId}/integrations/slack/reply`}>
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'mattermost':
            return (
              <Link to={`/inboxes/${inboxId}/integrations/mattermost`}>
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'gmail':
            return (
              <Link to={`/inboxes/${inboxId}/integrations/google/gmail`}>
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'twilio':
            return (
              <Link to={`/inboxes/${inboxId}/integrations/twilio`}>
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'slack:sync':
            return (
              <Link to={`/inboxes/${inboxId}/integrations/slack/support`}>
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          default:
            return <Button disabled>Coming soon!</Button>;
        }
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={integrations}
      columns={columns}
      pagination={false}
    />
  );
};

type Props = {inbox: Inbox};
type State = {
  loading: boolean;
  refreshing: boolean;
  integrations: Array<IntegrationType>;
};

class InboxIntegrations extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    integrations: [],
  };

  async componentDidMount() {
    try {
      const integrations = await Promise.all([
        this.fetchChatIntegration(),
        this.fetchSlackIntegration(),
        this.fetchMattermostIntegration(),
        this.fetchGmailIntegration(),
        this.fetchTwilioIntegration(),
        this.fetchMicrosoftTeamsIntegration(),
        this.fetchWhatsAppIntegration(),
        // TODO: deprecate
        this.fetchSlackSupportIntegration(),
      ]);

      this.setState({
        loading: false,
        integrations: integrations.filter(({key}) =>
          isEuEdition ? !key.startsWith('slack') : true
        ),
      });
    } catch (err) {
      logger.error('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

  refreshAllIntegrations = async () => {
    try {
      this.setState({refreshing: true});

      const integrations = await Promise.all([
        this.fetchChatIntegration(),
        this.fetchSlackIntegration(),
        this.fetchMattermostIntegration(),
        this.fetchGmailIntegration(),
        this.fetchTwilioIntegration(),
        this.fetchMicrosoftTeamsIntegration(),
        this.fetchWhatsAppIntegration(),
        // TODO: deprecate
        this.fetchSlackSupportIntegration(),
      ]);

      this.setState({
        integrations: integrations.filter(({key}) =>
          isEuEdition ? !key.startsWith('slack') : true
        ),
        refreshing: false,
      });
    } catch (err) {
      logger.error('Error refreshing integrations:', err);

      this.setState({refreshing: false});
    }
  };

  fetchChatIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId, account_id: accountId} = this.props.inbox;
    const widgetSettings = await API.fetchWidgetSettings({
      account_id: accountId,
      inbox_id: inboxId,
    });
    const {count = 0} = await API.countAllConversations({inbox_id: inboxId});
    const {id: widgetSettingsId, created_at: createdAt} = widgetSettings;
    const description = 'Chat with users on your website via Papercups.';
    const isConnected = count > 0;

    return {
      key: 'chat',
      integration: 'Live chat',
      status: isConnected ? 'connected' : 'not_connected',
      created_at: isConnected ? createdAt : null,
      icon: '/logo.svg',
      description,
      // TODO: deprecate?
      authorization_id: widgetSettingsId || null,
    };
  };

  fetchSlackIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId} = this.props.inbox;
    const auth = await API.fetchSlackAuthorization('reply', {
      inbox_id: inboxId,
    });
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Reply to messages from your customers directly through Slack.';

    return {
      key: 'slack',
      integration: 'Reply from Slack',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/slack.svg',
      description,
    };
  };

  fetchMattermostIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId} = this.props.inbox;
    const auth = await API.fetchMattermostAuthorization({inbox_id: inboxId});
    const isConnected =
      auth && auth.channel && auth.access_token && auth.verification_token;
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Reply to messages from your customers directly from Mattermost.';

    return {
      key: 'mattermost',
      integration: 'Reply from Mattermost',
      status: isConnected ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/mattermost.svg',
      description,
    };
  };

  fetchSlackSupportIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId} = this.props.inbox;
    const auth = await API.fetchSlackAuthorization('support', {
      inbox_id: inboxId,
    });
    const description =
      auth && auth.channel && auth.team_name
        ? `Connected to ${auth.channel} in ${auth.team_name}.`
        : 'Sync messages from your Slack channels with Papercups.';

    return {
      key: 'slack:sync',
      integration: 'Sync with Slack (beta)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/slack.svg',
      description,
    };
  };

  fetchGmailIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId} = this.props.inbox;
    const auth = await API.fetchGoogleAuthorization({
      client: 'gmail',
      type: 'support',
      inbox_id: inboxId,
    });

    return {
      key: 'gmail',
      integration: 'Gmail (beta)',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/gmail.svg',
      description: 'Sync messages from your Gmail inbox with Papercups.',
    };
  };

  fetchMicrosoftTeamsIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'microsoft-teams',
      integration: 'Microsoft Teams',
      status: 'not_connected',
      created_at: null,
      authorization_id: null,
      icon: '/microsoft-teams.svg',
    };
  };

  fetchTwilioIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId} = this.props.inbox;
    const auth = await API.fetchTwilioAuthorization({inbox_id: inboxId});

    return {
      key: 'twilio',
      integration: 'Twilio',
      status: auth ? 'connected' : 'not_connected',
      created_at: auth ? auth.created_at : null,
      authorization_id: auth ? auth.id : null,
      icon: '/twilio.svg',
      description: 'Receive and reply to messages over SMS.',
    };
  };

  fetchWhatsAppIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'whatsapp',
      integration: 'WhatsApp',
      status: 'not_connected',
      created_at: null,
      authorization_id: null,
      icon: '/whatsapp.svg',
    };
  };

  render() {
    const {id: inboxId} = this.props.inbox;
    const {loading, refreshing, integrations = []} = this.state;

    return (
      <Box>
        <Box px={3} mb={3}>
          <Title level={4}>Integrations</Title>
        </Box>
        <Box my={3}>
          <InboxIntegrationsTable
            loading={loading || refreshing}
            inboxId={inboxId}
            integrations={integrations}
          />
        </Box>
      </Box>
    );
  }
}

export default InboxIntegrations;
