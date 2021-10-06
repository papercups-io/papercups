import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import {Box, Flex} from 'theme-ui';
import {colors, Button, Table, Tag, Text} from '../common';
import {PlusOutlined, SettingOutlined} from '../icons';
import {IntegrationType} from './support';
import {Papercups} from '@papercups-io/chat-widget';

const IntegrationsTable = ({
  loading,
  integrations,
}: {
  loading?: boolean;
  integrations: Array<IntegrationType>;
}) => {
  const isChatAvailable = !!document.querySelector(
    '.Papercups-chatWindowContainer'
  );
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
              <img
                src={icon}
                alt={value}
                style={{maxHeight: 20, maxWidth: 20}}
              />
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
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (value: string) => {
        if (!value) {
          return '--';
        }

        return dayjs(value).format('MMM DD, YYYY');
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (action: any, record: IntegrationType) => {
        const {key, status} = record;
        const isConnected = status === 'connected';

        // TODO: DRY this up!
        switch (key) {
          case 'sheets':
            return (
              <Link to="/integrations/google/sheets">
                {isConnected ? (
                  <Button icon={<SettingOutlined />}>Configure</Button>
                ) : (
                  <Button icon={<PlusOutlined />}>Add</Button>
                )}
              </Link>
            );

          case 'github':
            return (
              <Link to="/integrations/github">
                {isConnected ? (
                  <Button icon={<SettingOutlined />}>Configure</Button>
                ) : (
                  <Button icon={<PlusOutlined />}>Add</Button>
                )}
              </Link>
            );

          case 'hubspot':
            return (
              <Link to="/integrations/hubspot">
                {isConnected ? (
                  <Button icon={<SettingOutlined />}>Configure</Button>
                ) : (
                  <Button icon={<PlusOutlined />}>Add</Button>
                )}
              </Link>
            );

          case 'intercom':
            return (
              <Link to="/integrations/intercom">
                {isConnected ? (
                  <Button icon={<SettingOutlined />}>Configure</Button>
                ) : (
                  <Button icon={<PlusOutlined />}>Add</Button>
                )}
              </Link>
            );

          default:
            return isChatAvailable ? (
              <Button onClick={Papercups.toggle}>Chat with us!</Button>
            ) : (
              <Button disabled>Coming soon!</Button>
            );
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
