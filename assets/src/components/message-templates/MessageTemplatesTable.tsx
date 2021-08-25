import React from 'react';
import {Link} from 'react-router-dom';
import {Button, Table} from '../common';
import {MessageTemplate} from '../../types';

export const MessageTemplatesTable = ({
  loading,
  messageTemplates,
}: {
  loading?: boolean;
  messageTemplates: Array<MessageTemplate>;
}) => {
  const data = messageTemplates
    .map((messageTemplate) => {
      return {key: messageTemplate.id, ...messageTemplate};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Last updated at',
      dataIndex: 'updated_at',
      key: 'updated_at',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: messageTemplateId} = record;

        return (
          <Link to={`/message-templates/${messageTemplateId}`}>
            <Button>View</Button>
          </Link>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

export default MessageTemplatesTable;
