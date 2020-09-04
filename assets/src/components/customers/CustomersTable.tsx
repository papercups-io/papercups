import React from 'react';
import {Box} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Badge, Button, Table, Text, Tooltip} from '../common';
import CustomerDetailsModal from './CustomerDetailsModal';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const CustomersTable = ({
  customers,
  currentlyOnline,
}: {
  customers: Array<any>;
  currentlyOnline: any;
}) => {
  const [selectedCustomerId, setSelectedCustomerId] = React.useState(null);

  const isCustomerOnline = (customer: any) => {
    const {id: customerId} = customer;

    return currentlyOnline[customerId];
  };

  const data = customers
    .filter((customer) => !!customer.email) // Only show customers with email for now
    .map((customer) => {
      return {key: customer.id, ...customer};
    })
    .sort((a, b) => {
      if (isCustomerOnline(a)) {
        return -1;
      } else if (isCustomerOnline(b)) {
        return 1;
      }

      // TODO: fix how we set `last_seen`!
      return +new Date(b.last_seen) - +new Date(a.last_seen);
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
        return value || '--';
      },
    },
    {
      title: 'Last seen',
      dataIndex: 'last_seen',
      key: 'last_seen',
      render: (value: string, record: any) => {
        const {id, pathname, current_url} = record;
        const formatted = dayjs.utc(value).format('MMMM DD, YYYY');
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
      title: 'Device info',
      dataIndex: 'info',
      key: 'info',
      render: (value: string, record: any) => {
        const {browser, os} = record;

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
      render: (value: string, record: any) => {
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
            />
          </>
        );
      },
    },
  ];

  return <Table dataSource={data} columns={columns} />;
};

export default CustomersTable;
