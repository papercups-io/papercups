import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Table, Tag, Text, Tooltip} from '../common';
import {SettingOutlined} from '../icons';
import {IntegrationType, getGoogleAuthUrl} from './support';
import {MattermostAuthorizationButton} from './MattermostAuthorizationModal';
import {TwilioAuthorizationButton} from './TwilioAuthorizationModal';
import {SupportGmailAuthorizationButton} from './GoogleAuthorizationButton';
import {GithubAuthorizationButton} from './GithubAuthorizationButton';

const IntegrationsTable = ({
  loading,
  integrations,
  onDisconnectSlack,
  onDisconnectGmail,
  onUpdateIntegration,
}: {
  loading?: boolean;
  integrations: Array<IntegrationType>;
  onDisconnectSlack: (id: string) => void;
  onDisconnectGmail: (id: string) => void;
  onUpdateIntegration: (data?: any) => void;
}) => {
  const columns = [
    {
      title: 'Integration',
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
        const {key, status, authorization_id: authorizationId} = record;
        const isConnected = status === 'connected';

        switch (key) {
          case 'slack':
            return (
              <Link to="/integrations/slack/reply">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'mattermost':
            return (
              <MattermostAuthorizationButton
                integration={record}
                onUpdate={onUpdateIntegration}
              />
            );
          case 'gmail':
            return (
              <SupportGmailAuthorizationButton
                isConnected={isConnected}
                authorizationId={authorizationId}
                onDisconnectGmail={onDisconnectGmail}
              />
            );
          case 'sheets':
            return (
              <Tooltip
                title={
                  <Box>
                    Our verification with the Google API is pending, but you can
                    still link your Google Sheets account to opt into new
                    features.
                  </Box>
                }
              >
                <a href={getGoogleAuthUrl({client: 'sheets'})}>
                  <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
                </a>
              </Tooltip>
            );
          case 'twilio':
            return (
              <TwilioAuthorizationButton
                integration={record}
                onUpdate={onUpdateIntegration}
              />
            );
          case 'github':
            return (
              <GithubAuthorizationButton
                integration={record}
                onUpdate={onUpdateIntegration}
              />
            );
          case 'slack:sync':
            return (
              <Link to="/integrations/slack/support">
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

export default IntegrationsTable;
