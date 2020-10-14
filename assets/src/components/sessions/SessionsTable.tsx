import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Button, Table} from '../common';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const Sessions = ({sessions}: {sessions: Array<any>}) => {
  const data = sessions.map((session) => {
    return {key: session.id, ...session};
  });
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      render: (id: string) => {
        return <Link to={`/sessions/${id}`}>{id}</Link>;
      },
    },
    {
      title: 'Started at',
      dataIndex: 'started_at',
      key: 'started_at',
      render: (value: string) => {
        return value ? dayjs(value).format('MMMM DD, h:mm a') : '--';
      },
    },
    {
      title: 'Finished at',
      dataIndex: 'finished_at',
      key: 'finished_at',
      render: (value: string) => {
        return value ? dayjs(value).format('MMMM DD, h:mm a') : '--';
      },
    },

    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        const {id: sessionId} = record;

        return (
          <Link to={`/sessions/${sessionId}`}>
            <Button>View</Button>
          </Link>
        );
      },
    },
  ];

  return <Table dataSource={data} columns={columns} />;
};

export default Sessions;
