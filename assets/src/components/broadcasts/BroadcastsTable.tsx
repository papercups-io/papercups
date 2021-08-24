import React from 'react';
import {Link} from 'react-router-dom';
import {Button, Table} from '../common';
import {Broadcast} from '../../types';

export const BroadcastsTable = ({
  loading,
  broadcasts,
}: {
  loading?: boolean;
  broadcasts: Array<Broadcast>;
}) => {
  const data = broadcasts
    .map((broadcast) => {
      return {key: broadcast.id, ...broadcast};
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
    // {
    //   title: 'Description',
    //   dataIndex: 'description',
    //   key: 'description',
    //   render: (value: string) => {
    //     return value || '--';
    //   },
    // },
    {
      title: 'Status',
      dataIndex: 'state',
      key: 'state',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Started',
      dataIndex: 'started_at',
      key: 'started_at',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Finished',
      dataIndex: 'finished_at',
      key: 'finished_at',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: broadcastId} = record;

        return (
          <Link to={`/broadcasts/${broadcastId}`}>
            <Button>View</Button>
          </Link>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

export default BroadcastsTable;
