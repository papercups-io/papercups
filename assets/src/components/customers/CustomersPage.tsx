import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Alert, Badge, Paragraph, Table, Text, Title, Tooltip} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import * as API from '../../api';
import Spinner from '../Spinner';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

type Props = {
  currentlyOnline?: any;
};
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

  isCustomerOnline = (customer: any) => {
    const {currentlyOnline = {}} = this.props;
    const {id: customerId} = customer;

    return currentlyOnline[customerId];
  };

  renderCustomersTable = (customers: Array<any>) => {
    const {currentlyOnline} = this.props;
    const data = customers
      .filter((customer) => !!customer.email) // Only show customers with email for now
      .map((customer) => {
        return {key: customer.id, ...customer};
      })
      .sort((a, b) => {
        if (this.isCustomerOnline(a)) {
          return -1;
        } else if (this.isCustomerOnline(b)) {
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

const CustomersPageWrapper = () => {
  const {currentlyOnline = {}} = useConversations();
  const online = Object.keys(currentlyOnline).reduce((acc, key: string) => {
    const [prefix, id] = key.split(':');

    if (prefix === 'customer' && !!id) {
      return {...acc, [id]: true};
    }

    return acc;
  }, {} as {[key: string]: boolean});

  return <CustomersPage currentlyOnline={online} />;
};

export default CustomersPageWrapper;
