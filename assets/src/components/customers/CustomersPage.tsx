import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import {Alert, Paragraph, Table, Text, Title, Tooltip} from '../common';
import * as API from '../../api';
import Spinner from '../Spinner';

type Props = {};
type State = {
  loading: boolean;
  customers: Array<any>;
};

class CustomersPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    customers: [],
  };

  async componentDidMount() {
    try {
      const customers = await API.fetchCustomers();

      this.setState({customers, loading: false});
    } catch (err) {
      console.error('Error loading customers!', err);

      this.setState({loading: false});
    }
  }

  renderCustomersTable = (customers: Array<any>) => {
    const data = customers
      .filter((customer) => !!customer.email) // Only show customers with email for now
      .map((customer) => {
        return {key: customer.id, ...customer};
      })
      .sort((a, b) => +new Date(b.last_seen) - +new Date(a.last_seen));

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
          const {pathname, current_url} = record;
          const formatted = dayjs(value).format('MMMM DD, YYYY');

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
    ];

    return <Table dataSource={data} columns={columns} />;
  };

  render() {
    const {loading, customers = []} = this.state;

    if (loading) {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    }

    return (
      <Box p={4}>
        <Box mb={5}>
          <Title level={3}>Customers (beta)</Title>

          <Box mb={4}>
            <Paragraph>
              View the people that have interacted with you most recently and
              have provided an email address.
            </Paragraph>

            <Alert
              message={
                <Text>
                  This page is still a work in progress &mdash; more features
                  coming soon!
                </Text>
              }
              type="info"
              showIcon
            />
          </Box>

          {this.renderCustomersTable(customers)}
        </Box>
      </Box>
    );
  }
}

export default CustomersPage;
