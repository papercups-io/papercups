import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import {colors, Button, Popconfirm, Table, Tag, Text} from '../common';
import {WebhookEventSubscription} from './support';

const WebhooksTable = ({
  webhooks,
  onUpdateWebhook,
  onDeleteWebhook,
}: {
  webhooks: Array<WebhookEventSubscription>;
  onUpdateWebhook: (webhook: WebhookEventSubscription) => void;
  onDeleteWebhook: (webhook: WebhookEventSubscription) => void;
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
      render: (action: any, record: WebhookEventSubscription) => {
        return (
          <Flex mx={-1}>
            <Box mx={1}>
              <Button onClick={() => onUpdateWebhook(record)}>Update</Button>
            </Box>
            <Box mx={1}>
              {/* TODO: maybe use an icon here instead? (and figure out how to animate deletions) */}
              <Popconfirm
                title="Are you sure you want to delete this webhook?"
                okText="Yes"
                cancelText="No"
                placement="topLeft"
                onConfirm={() => onDeleteWebhook(record)}
              >
                <Button danger>Remove</Button>
              </Popconfirm>
            </Box>
          </Flex>
        );
      },
    },
  ];

  return <Table rowKey="id" dataSource={webhooks} columns={columns} />;
};

export default WebhooksTable;
