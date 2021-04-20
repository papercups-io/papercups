import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Popconfirm, Table, Tag, Text, Tooltip} from '../common';
import {IntegrationType, getSlackAuthUrl, getGoogleAuthUrl} from './support';
import {MattermostAuthorizationButton} from './MattermostAuthorizationModal';
import {TwilioAuthorizationButton} from './TwilioAuthorizationModal';
import {GoogleAuthorizationButton} from './GoogleAuthorizationButton';
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
            if (isConnected && authorizationId) {
              return (
                <Flex mx={-1}>
                  <Box mx={1}>
                    <a href={getSlackAuthUrl('reply')}>
                      <Button>Reconnect</Button>
                    </a>
                  </Box>
                  <Box mx={1}>
                    <Popconfirm
                      title="Are you sure you want to disconnect from Slack?"
                      okText="Yes"
                      cancelText="No"
                      placement="topLeft"
                      onConfirm={() => onDisconnectSlack(authorizationId)}
                    >
                      <Button danger>Disconnect</Button>
                    </Popconfirm>
                  </Box>
                </Flex>
              );
            }

            return (
              <a href={getSlackAuthUrl('reply')}>
                <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
              </a>
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
              <GoogleAuthorizationButton
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
                <a href={getGoogleAuthUrl('sheets')}>
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
          // TODO: deprecate
          case 'slack:sync':
            if (isConnected && authorizationId) {
              return (
                <Flex mx={-1}>
                  <Box mx={1}>
                    <a href={getSlackAuthUrl('support')}>
                      <Button>Reconnect</Button>
                    </a>
                  </Box>
                  <Box mx={1}>
                    <Popconfirm
                      title="Are you sure you want to disconnect from Slack?"
                      okText="Yes"
                      cancelText="No"
                      placement="topLeft"
                      onConfirm={() => onDisconnectSlack(authorizationId)}
                    >
                      <Button danger>Disconnect</Button>
                    </Popconfirm>
                  </Box>
                </Flex>
              );
            }

            return (
              <a href={getSlackAuthUrl('support')}>
                <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
              </a>
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
