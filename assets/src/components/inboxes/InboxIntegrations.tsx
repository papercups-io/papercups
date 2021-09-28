import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';

import {colors, Button, Divider, Table, Tag, Text, Title} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {IntegrationType} from '../integrations/support';
import {isEuEdition} from '../../config';
import {PlusOutlined, SettingOutlined} from '../icons';
import {Inbox} from '../../types';

const getDefaultConfigurationUrl = (key: string, inboxId: string) => {
  switch (key) {
    case 'chat':
      return `/inboxes/${inboxId}/chat-widget`;
    case 'slack':
      return `/inboxes/${inboxId}/integrations/slack/reply`;
    case 'mattermost':
      return `/inboxes/${inboxId}/integrations/mattermost`;
    case 'gmail':
      return `/inboxes/${inboxId}/integrations/google/gmail`;
    case 'ses':
      return `/inboxes/${inboxId}/email-forwarding`;
    case 'twilio':
      return `/inboxes/${inboxId}/integrations/twilio`;
    case 'slack:sync':
      return `/inboxes/${inboxId}/integrations/slack/support`;
    default:
      return null;
  }
};

export const InboxIntegrationsTable = ({
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
        const {icon, description, isPopular} = record;

        return (
          <Box>
            <Flex sx={{alignItems: 'center'}}>
              <img src={icon} alt={value} style={{height: 20}} />
              <Text strong style={{marginLeft: 8, marginRight: 8}}>
                {value}
              </Text>
              {isPopular && <Tag color="blue">Popular</Tag>}
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
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (value: string) => {
        if (!value) {
          return '--';
        }

        return dayjs(value).format('MMM D, YYYY');
      },
    },
    {
      title: '',
      dataIndex: 'configurationUrl',
      key: 'configurationUrl',
      render: (configurationUrl: string | null, record: IntegrationType) => {
        const {key, status} = record;
        const isConnected = status === 'connected';
        const url =
          configurationUrl || getDefaultConfigurationUrl(key, inboxId);

        if (!url) {
          return null;
        }

        return (
          <Link to={url}>
            {isConnected ? (
              <Button icon={<SettingOutlined />}>Configure</Button>
            ) : (
              <Button icon={<PlusOutlined />}>Add</Button>
            )}
          </Link>
        );
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
  integrationsByKey: {[key: string]: IntegrationType};
};

class InboxIntegrations extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    integrations: [],
    integrationsByKey: {},
  };

  async componentDidMount() {
    try {
      const integrations = await Promise.all([
        this.fetchChatIntegration(),
        this.fetchSlackIntegration(),
        this.fetchEmailForwardingIntegration(),
        this.fetchMattermostIntegration(),
        this.fetchGmailIntegration(),
        this.fetchTwilioIntegration(),
        this.fetchSlackSupportIntegration(),
      ]);

      this.setState({
        loading: false,
        integrations: integrations.filter(({key}) =>
          isEuEdition ? !key.startsWith('slack') : true
        ),
        integrationsByKey: integrations.reduce((acc, integration) => {
          return {...acc, [integration.key]: integration};
        }, {}),
      });
    } catch (err) {
      logger.error('Error loading integrations:', err);

      this.setState({loading: false});
    }
  }

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
      createdAt: isConnected ? createdAt : null,
      icon: '/logo.svg',
      isPopular: true,
      description,
      configurationUrl: `/inboxes/${inboxId}/chat-widget`,
      // TODO: deprecate?
      authorizationId: widgetSettingsId || null,
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
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/slack.svg',
      isPopular: true,
      description,
      configurationUrl: `/inboxes/${inboxId}/integrations/slack/reply`,
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
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/mattermost.svg',
      description,
      configurationUrl: `/inboxes/${inboxId}/integrations/mattermost`,
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
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/slack.svg',
      description,
      configurationUrl: `/inboxes/${inboxId}/integrations/slack/support`,
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
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/gmail.svg',
      description: 'Sync messages from your Gmail inbox with Papercups.',
      configurationUrl: `/inboxes/${inboxId}/integrations/google/gmail`,
    };
  };

  fetchEmailForwardingIntegration = async (): Promise<IntegrationType> => {
    const {id: inboxId} = this.props.inbox;
    const addresses = await API.fetchForwardingAddresses({inbox_id: inboxId});
    const [first] = addresses;

    return {
      key: 'ses',
      integration: 'Email forwarding',
      status: first ? 'connected' : 'not_connected',
      createdAt: first ? first.created_at : null,
      authorizationId: first ? first.id : null,
      icon: '/ses.svg',
      isPopular: true,
      description: 'Set up email forwarding into Papercups.',
      configurationUrl: `/inboxes/${inboxId}/email-forwarding`,
    };
  };

  fetchMicrosoftTeamsIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'microsoft-teams',
      integration: 'Microsoft Teams',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
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
      createdAt: auth ? auth.created_at : null,
      authorizationId: auth ? auth.id : null,
      icon: '/twilio.svg',
      description: 'Receive and reply to messages over SMS.',
      configurationUrl: `/inboxes/${inboxId}/integrations/twilio`,
    };
  };

  fetchWhatsAppIntegration = async (): Promise<IntegrationType> => {
    return {
      key: 'whatsapp',
      integration: 'WhatsApp',
      status: 'not_connected',
      createdAt: null,
      authorizationId: null,
      icon: '/whatsapp.svg',
    };
  };

  getIntegrationsByKeys = (keys: Array<string>) => {
    const {integrationsByKey = {}} = this.state;

    return keys.map((key) => integrationsByKey[key] || null).filter(Boolean);
  };

  getInboxSourceChannels = () => {
    return this.getIntegrationsByKeys([
      'chat',
      'ses',
      'gmail',
      'twilio',
      'slack:sync',
    ]);
  };

  getInboxReplyChannels = () => {
    return this.getIntegrationsByKeys(['slack', 'mattermost']);
  };

  render() {
    const {id: inboxId} = this.props.inbox;
    const {loading, refreshing} = this.state;
    const sources = this.getInboxSourceChannels();
    const replies = this.getInboxReplyChannels();

    return (
      <Box>
        <Box px={3} mb={3}>
          <Title level={4}>Source channels</Title>
        </Box>
        <Box mb={4}>
          <InboxIntegrationsTable
            loading={loading || refreshing}
            inboxId={inboxId}
            integrations={sources}
          />
        </Box>

        <Divider />

        <Box px={3} mb={3}>
          <Title level={4}>Reply channels</Title>
        </Box>
        <Box mb={4}>
          <InboxIntegrationsTable
            loading={loading || refreshing}
            inboxId={inboxId}
            integrations={replies}
          />
        </Box>
      </Box>
    );
  }
}

export default InboxIntegrations;
