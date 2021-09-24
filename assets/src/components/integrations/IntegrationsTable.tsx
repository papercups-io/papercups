import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Table, Tag, Text} from '../common';
import {SettingOutlined} from '../icons';
import {IntegrationType} from './support';

const IntegrationsTable = ({
  loading,
  integrations,
}: {
  loading?: boolean;
  integrations: Array<IntegrationType>;
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
        const {key} = record;

        switch (key) {
          case 'chat':
            return (
              <Link to="/settings/chat-widget">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'slack':
            return (
              <Link to="/integrations/slack/reply">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'mattermost':
            return (
              <Link to="/integrations/mattermost">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'gmail':
            return (
              <Link to="/integrations/google/gmail">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'ses':
            return (
              <Link to="/settings/email-forwarding">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'sheets':
            return (
              <Link to="/integrations/google/sheets">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'twilio':
            return (
              <Link to="/integrations/twilio">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
            );
          case 'github':
            return (
              <Link to="/integrations/github">
                <Button icon={<SettingOutlined />}>Configure</Button>
              </Link>
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
