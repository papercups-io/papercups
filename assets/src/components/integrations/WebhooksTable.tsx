import React from 'react';
import dayjs from 'dayjs';
import {colors, Button, Table, Tag, Text} from '../common';
import {WebhookEventSubscription} from './support';

const WebhooksTable = ({
  webhooks,
  onUpdateWebhook,
}: {
  webhooks: Array<WebhookEventSubscription>;
  onUpdateWebhook: (webhook: WebhookEventSubscription) => void;
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
        return <Button onClick={() => onUpdateWebhook(record)}>Update</Button>;
      },
    },
  ];

  return <Table rowKey="id" dataSource={webhooks} columns={columns} />;
};

export default WebhooksTable;
