import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {colors, Button, Popconfirm, Table, Tag, Text, Tooltip} from '../common';
import {SLACK_CLIENT_ID, isDev} from '../../config';
import {IntegrationType} from './support';

const getSlackAuthUrl = (type = 'reply') => {
  const origin = window.location.origin;
  const redirect = `${origin}/integrations/slack`;
  const scopes = [
    'incoming-webhook',
    'chat:write',
    'channels:history',
    'channels:manage',
    'channels:read',
    'chat:write.public',
    'chat:write.customize',
    'users:read',
    'users:read.email',
    'groups:history',
    'groups:read',
    'reactions:read',
  ];
  const userScopes = ['channels:history', 'groups:history', 'chat:write'];
  const q = {
    state: type,
    scope: scopes.join(' '),
    user_scope: userScopes.join(' '),
    client_id: SLACK_CLIENT_ID,
    redirect_uri: redirect,
  };
  const query = qs.stringify(q);

  return `https://slack.com/oauth/v2/authorize?${query}`;
};

const getGmailAuthUrl = () => {
  const origin = isDev ? 'http://localhost:4000' : window.location.origin;

  return `${origin}/gmail/auth`;
};

const IntegrationsTable = ({
  loading,
  integrations,
  onDisconnectSlack,
}: {
  loading?: boolean;
  integrations: Array<IntegrationType>;
  onDisconnectSlack: (id: string) => void;
}) => {
  const columns = [
    {
      title: 'Integration',
      dataIndex: 'integration',
      key: 'integration',
      render: (value: string, record: IntegrationType) => {
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
          case 'gmail':
            return (
              <Tooltip
                title={
                  <Box>
                    Our verification with the Google API is pending, but you can
                    still link your Gmail account to opt into new features.
                  </Box>
                }
              >
                <a href={getGmailAuthUrl()}>
                  <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
                </a>
              </Tooltip>
            );
          default:
            return <Button disabled>Coming soon!</Button>;
        }
      },
    },
  ];

  return (
    <Table loading={loading} dataSource={integrations} columns={columns} />
  );
};

export default IntegrationsTable;
