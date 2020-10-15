import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {BrowserSession} from '../../types';
import {formatDiffDuration} from '../../utils';
import {Badge, Button, Table} from '../common';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const SessionsTable = ({sessions}: {sessions: Array<BrowserSession>}) => {
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
        return value ? (
          dayjs(value).format('MMMM DD, h:mm a')
        ) : (
          <Badge status="processing" text="Online now!" />
        );
      },
    },
    {
      title: 'Duration',
      dataIndex: 'duration',
      key: 'duration',
      render: (v: string, record: BrowserSession) => {
        const {started_at, finished_at} = record;

        if (!finished_at) {
          return '--';
        }

        const startedAt = dayjs(started_at);
        const finishedAt = dayjs(finished_at);
        const duration = formatDiffDuration(startedAt, finishedAt);

        return duration || '--';
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
            <Button>View replay</Button>
          </Link>
        );
      },
    },
  ];

  return <Table dataSource={data} columns={columns} />;
};

export default SessionsTable;
