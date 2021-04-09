import React from 'react';
import {Box} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Customer} from '../../types';
import {Badge, Button, Table, Text, Tooltip} from '../common';
import CustomerDetailsModal from './CustomerDetailsModal';
import {TablePaginationConfig} from 'antd/lib/table';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const CustomersTable = ({
  loading,
  customers,
  currentlyOnline = {},
  shouldIncludeAnonymous,
  action,
  onUpdate,
  pagination,
}: {
  loading?: boolean;
  customers: Array<Customer>;
  currentlyOnline?: Record<string, any>;
  shouldIncludeAnonymous?: boolean;
  action?: (customer: Customer) => React.ReactElement;
  pagination?: false | TablePaginationConfig;
  onUpdate: () => Promise<void>;
}) => {
  const [selectedCustomerId, setSelectedCustomerId] = React.useState<
    string | null
  >(null);

  const isCustomerOnline = (customer: Customer) => {
    const {id: customerId} = customer;

    return currentlyOnline[customerId];
  };

  const data = customers
    // Only show customers with email by default
    .filter((customer) => (shouldIncludeAnonymous ? true : !!customer.email))
    .map((customer) => {
      return {key: customer.id, ...customer};
    })
    // TODO: make sorting configurable from the UI
    .sort((a, b) => {
      if (isCustomerOnline(a)) {
        return -1;
      } else if (isCustomerOnline(b)) {
        return 1;
      }

      const bLastSeen = b.last_seen_at || b.last_seen;
      const aLastSeen = a.last_seen_at || a.last_seen;

      // TODO: fix how we set `last_seen`!
      return +new Date(bLastSeen) - +new Date(aLastSeen);
    });

  const columns = [
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string) => {
        return value || 'Anonymous User';
      },
    },
    {
      title: 'Last seen',
      dataIndex: 'last_seen_at',
      key: 'last_seen_at',
      render: (value: string, record: Customer) => {
        const {id, pathname, current_url, last_seen} = record;
        const formatted = dayjs.utc(value || last_seen).format('MMMM DD, YYYY');
        const isOnline = currentlyOnline[id];

        if (isOnline) {
          return <Badge status="processing" text="Online now!" />;
        }

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
      title: 'Timezone',
      dataIndex: 'time_zone',
      key: 'time_zone',
      render: (value: string) => {
        return value ? <Text>{value}</Text> : <Text type="secondary">--</Text>;
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: Customer) => {
        if (action && typeof action === 'function') {
          return action(record);
        }

        const {id: customerId} = record;

        return (
          <>
            <Button onClick={() => setSelectedCustomerId(customerId)}>
              View more
            </Button>
            <CustomerDetailsModal
              customer={record}
              isVisible={selectedCustomerId === record.id}
              onClose={() => setSelectedCustomerId(null)}
              onUpdate={onUpdate}
              onDelete={onUpdate}
            />
          </>
        );
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      pagination={pagination}
    />
  );
};

export default CustomersTable;
