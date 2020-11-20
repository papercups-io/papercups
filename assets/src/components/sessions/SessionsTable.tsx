import React from 'react';
import {Link} from 'react-router-dom';
import {Box} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {BrowserSession, Customer} from '../../types';
import {Badge, Button, Table, Text, Tooltip} from '../common';
import {formatRelativeTime} from '../../utils';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const SessionsTable = ({
  loading,
  sessions,
}: {
  loading?: boolean;
  sessions: Array<BrowserSession>;
}) => {
  const data = sessions.map((session) => {
    return {key: session.id, ...session};
  });
  const columns = [
    {
      title: 'Visitor',
      dataIndex: 'customer',
      key: 'customer',
      render: (customer: Customer | null) => {
        if (!customer) {
          return 'Anonymous User';
        }

        return customer.email || customer.name || 'Anonymous User';
      },
    },
    {
      title: 'Started at',
      dataIndex: 'started_at',
      key: 'started_at',
      render: (value: string, record: BrowserSession) => {
        const {metadata = {}} = record;
        const {pathname, current_url} = metadata;
        const formatted = value ? dayjs(value).format('MMMM DD, h:mm a') : '--';

        return (
          <Box>
            <Text>{formatted}</Text>
            <Box sx={{fontSize: 12, lineHeight: 1.4}}>
              {pathname && (
                <Text type="secondary">
                  {' '}
                  on
                  <Tooltip title={current_url} placement="right">
                    <Text code>{pathname}</Text>
                  </Tooltip>
                </Text>
              )}
            </Box>
          </Box>
        );
      },
    },
    {
      title: 'Status',
      dataIndex: 'active',
      key: 'active',
      render: (isActive: boolean, record: BrowserSession) => {
        const {ts} = record;
        const date = ts ? dayjs.utc(ts) : null;

        return (
          <Box>
            {isActive ? (
              <Badge status="processing" text="Online now" />
            ) : (
              <Badge status="default" text="Inactive" />
            )}
            {date ? (
              <Box sx={{fontSize: 12, lineHeight: 1.4}}>
                <Text type="secondary">{formatRelativeTime(date)}</Text>
              </Box>
            ) : null}
          </Box>
        );
      },
    },
    {
      title: 'Device info',
      dataIndex: 'info',
      key: 'info',
      render: (value: string, record: BrowserSession) => {
        const {metadata = {}} = record;
        const {browser, os} = metadata;

        return (
          <Text>
            <Text type="secondary">{browser}</Text>
            {browser && os ? ' · ' : ''}
            {os && <Text type="secondary">{os}</Text>}
          </Text>
        );
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: BrowserSession) => {
        const {id: sessionId} = record;

        return (
          <Link to={`/sessions/live/${sessionId}`}>
            <Button>View live</Button>
          </Link>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

export default SessionsTable;
