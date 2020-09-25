import React from 'react';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {colors, Button, Table, Tag, Text, Tooltip} from '../common';
import {SLACK_CLIENT_ID, isDev} from '../../config';
import {IntegrationType} from './support';

const getSlackAuthUrl = () => {
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

  return `https://slack.com/oauth/v2/authorize?${query}`;
};

const getGmailAuthUrl = () => {
  const origin = isDev ? 'http://localhost:4000' : window.location.origin;

  return `${origin}/gmail/auth`;
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

        switch (key) {
          case 'slack':
            return (
              <a href={getSlackAuthUrl()}>
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

  return <Table dataSource={integrations} columns={columns} />;
};

export default IntegrationsTable;
