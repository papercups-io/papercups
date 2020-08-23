import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {
  colors,
  Button,
  Input,
  Modal,
  Paragraph,
  Table,
  Tag,
  Text,
  Title,
} from '../common';
import {PlusOutlined} from '../icons';
import Spinner from '../Spinner';
import {SLACK_CLIENT_ID} from '../../config';
import * as API from '../../api';
import {sleep} from '../../utils';

type IntegrationType = {
  key: 'slack' | 'gmail';
  integration: string;
  status: 'connected' | 'not_connected';
  created_at?: string | null;
  icon: string;
};

type WebhookEventSubscription = {
  webhook_url: string;
  verified: boolean;
  created_at?: string | null;
};

const IntegrationsTable = ({
  integrations,
}: {
  integrations: Array<IntegrationType>;
}) => {
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
      title: '',
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
          scope:
            'incoming-webhook chat:write channels:history channels:manage chat:write.public users:read users:read.email',
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

  return <Table dataSource={integrations} columns={columns} />;
};

const WebhooksTable = ({
  webhooks,
}: {
  webhooks: Array<WebhookEventSubscription>;
}) => {
  const columns = [
    {
      title: 'Webhook URL',
      dataIndex: 'webhook_url',
      key: 'webhook_url',
      render: (value: string, record: any) => {
        return (
          <Text keyboard strong>
            {value}
          </Text>
        );
      },
    },
    {
      title: 'Status',
      dataIndex: 'verified',
      key: 'verified',
      render: (verified: boolean) => {
        return verified ? (
          <Tag color={colors.green}>Verified</Tag>
        ) : (
          <Tag>Unverified</Tag>
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
      render: (action: any, record: any) => {
        return <Button>Update</Button>;
      },
    },
  ];

  return <Table rowKey="id" dataSource={webhooks} columns={columns} />;
};

// TODO: clean up a bit
const NewWebhookModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (webhook: WebhookEventSubscription) => void;
  onCancel: () => void;
}) => {
  const [url, setWebhookUrl] = React.useState('');
  const [isVerifying, setIsVerifying] = React.useState(false);
  const [isVerified, setIsVerified] = React.useState(false);
  const [isSaving, setIsSaving] = React.useState(false);

  const handleChangeUrl = (e: any) => setWebhookUrl(e.target.value);

  const handleVerifyUrl = async () => {
    console.log('Verifying:', url);
    setIsVerifying(true);

    const {verified} = await API.verifyWebhookUrl(url);
    console.log('Verified?', verified);
    await sleep(1000);

    setIsVerifying(false);
    setIsVerified(verified);
  };

  const handleCancelWebhook = () => {
    onCancel();
    setWebhookUrl('');
    setIsVerified(false);
  };

  const handleSaveWebhook = async () => {
    console.log('Saving:', url);
    setIsSaving(true);

    const webhook = await API.createEventSubscriptions({
      webhook_url: url,
    });

    setIsSaving(false);
    onSuccess(webhook);
    setWebhookUrl('');
    setIsVerified(false);
  };

  return (
    <Modal
      title="Add webhook URL"
      visible={visible}
      onOk={handleSaveWebhook}
      onCancel={handleCancelWebhook}
      footer={[
        <Button key="cancel" onClick={handleCancelWebhook}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleSaveWebhook}
        >
          Save
        </Button>,
      ]}
    >
      <Box mb={2}>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <label htmlFor="webhook_url">Webhook URL</label>

          {isVerifying ? (
            <Text type="secondary">Verifying...</Text>
          ) : isVerified ? (
            <Text>Verified!</Text>
          ) : null}
        </Flex>
        <Input
          id="webhook_url"
          size="large"
          type="text"
          value={url}
          placeholder="https://myawesomeapp.com/api/webhook"
          onChange={handleChangeUrl}
          onBlur={handleVerifyUrl}
        />
      </Box>
    </Modal>
  );
};

type Props = RouteComponentProps<{type?: string}> & {};
type State = {
  loading: boolean;
  isWebhookModalOpen: boolean;
  integrations: Array<IntegrationType>;
  webhooks: Array<WebhookEventSubscription>;
};

class IntegrationsOverview extends React.Component<Props, State> {
  state: State = {
    loading: true,
    isWebhookModalOpen: false,
    integrations: [],
    webhooks: [],
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
      const webhooks = await API.fetchEventSubscriptions();

      this.setState({integrations, webhooks, loading: false});
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

  handleAddWebhook = () => {
    this.setState({isWebhookModalOpen: true});
  };

  refreshEventSubscriptions = async () => {
    try {
      const webhooks = await API.fetchEventSubscriptions();

      this.setState({webhooks});
    } catch (err) {
      console.log('Error refreshing event subscriptions:', err);
    }
  };

  handleWebhookModalSuccess = (webhook: WebhookEventSubscription) => {
    this.setState({
      webhooks: [...this.state.webhooks, webhook],
      isWebhookModalOpen: false,
    });

    this.refreshEventSubscriptions();
  };

  handleWebhookModalCancel = () => {
    this.setState({isWebhookModalOpen: false});
  };

  render() {
    const {
      loading,
      isWebhookModalOpen,
      webhooks = [],
      integrations = [],
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
        <Box mb={4}>
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
            <IntegrationsTable integrations={integrations} />
          </Box>
        </Box>

        <Box mb={4}>
          <Title level={4}>Event Subscriptions</Title>

          <Flex sx={{justifyContent: 'space-between', alignItems: 'baseline'}}>
            <Paragraph>
              <Text>
                Create your own integrations with custom webhooks{' '}
                <span role="img" aria-label=":)">
                  🤓
                </span>
              </Text>
            </Paragraph>

            <Button icon={<PlusOutlined />} onClick={this.handleAddWebhook}>
              Add webhook URL
            </Button>
          </Flex>

          <Box my={4}>
            <WebhooksTable webhooks={webhooks} />
          </Box>
        </Box>

        <NewWebhookModal
          visible={isWebhookModalOpen}
          onSuccess={this.handleWebhookModalSuccess}
          onCancel={this.handleWebhookModalCancel}
        />
      </Box>
    );
  }
}

export default IntegrationsOverview;
