import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Alert, Button, Input, Paragraph, Text, Title} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import * as API from '../../api';
import logger from '../../logger';
import {Customer, Pagination} from '../../types';
import Spinner from '../Spinner';
import CustomersTable from './CustomersTable';
import {NewCustomerButton} from './NewCustomerModal';

const filterCustomersByQuery = (
  customers: Array<Customer>,
  query?: string
): Array<Customer> => {
  if (!query || !query.length) {
    return customers;
  }

  return customers.filter((customer) => {
    const {
      name,
      email,
      phone,
      browser,
      os,
      time_zone: timeZone,
      current_url: url,
    } = customer;

    const words = [name, email, phone, browser, os, timeZone, url]
      .filter((str) => str && String(str).trim().length > 0)
      .join(' ')
      .replace('_', ' ')
      .split(' ')
      .map((str) => str.toLowerCase());

    const queries = query.split(' ').map((str) => str.toLowerCase());

    return words.some((word) => {
      return queries.every((q) => word.indexOf(q) !== -1);
    });
  });
};

type Props = {
  currentlyOnline?: any;
};
type State = {
  loading: boolean;
  refreshing: boolean;
  selectedCustomerId: string | null;
  query: string;
  customers: Array<Customer>;
  filteredCustomers: Array<Customer>;
  pagination: Pagination | null;
};

class CustomersPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    refreshing: false,
    selectedCustomerId: null,
    pagination: null,
    query: '',
    customers: [],
    filteredCustomers: [],
  };

  async componentDidMount() {
    try {
      const {data: customers, pagination} = await API.fetchCustomers({
        page: 1,
        page_size: 10,
      });

      this.setState({
        customers,
        loading: false,
        pagination,
      });
    } catch (err) {
      logger.error('Error loading customers!', err);

      this.setState({loading: false});
    }
  }

  handleRefreshCustomers = async () => {
    this.setState({refreshing: true});
    const {pagination} = this.state;

    try {
      const {data: customers} = await API.fetchCustomers({
        page: pagination?.page_number,
        page_size: pagination?.page_size,
      });

      this.setState({
        customers,
        refreshing: false,
      });
    } catch (err) {
      logger.error('Error refreshing customers!', err);

      this.setState({refreshing: false});
    }
  };

  handlePageChange = async (page: number, page_size?: number) => {
    this.setState({refreshing: true});

    try {
      const {data: customers, pagination} = await API.fetchCustomers({
        page,
        page_size,
      });

      this.setState({
        customers,
        refreshing: false,
        pagination: pagination,
      });
    } catch (err) {
      logger.error('Error paginating customers!', err);

      this.setState({refreshing: false});
    }
  };

  handleSearchCustomers = (query: string) => {
    const {customers = []} = this.state;

    if (!query || !query.length) {
      this.setState({query: '', filteredCustomers: customers});
    }

    this.setState({
      query,
    });
  };

  render() {
    const {currentlyOnline} = this.props;
    const {loading, refreshing, customers, pagination} = this.state;

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
      <Box p={4} sx={{maxWidth: 1080}}>
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

          <Flex mb={3} sx={{justifyContent: 'space-between'}}>
            <div />
            {/* <Input.Search
              placeholder="Search customers..."
              allowClear
              onSearch={this.handleSearchCustomers}
              style={{width: 400}}
            /> */}

            <NewCustomerButton onSuccess={this.handleRefreshCustomers} />
          </Flex>

          <CustomersTable
            loading={refreshing}
            customers={customers}
            currentlyOnline={currentlyOnline}
            onUpdate={this.handleRefreshCustomers}
            pagination={{
              total: pagination?.total_entries,
              onChange: this.handlePageChange,
            }}
            action={(customer: Customer) => (
              <Link to={`/customers/${customer.id}`}>
                <Button>View profile</Button>
              </Link>
            )}
          />
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
