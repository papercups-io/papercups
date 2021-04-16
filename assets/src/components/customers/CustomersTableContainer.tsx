import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {Customer, Pagination} from '../../types';
import CustomersTable from './CustomersTable';

type Props = {
  currentlyOnline?: any;
  defaultFilters?: Record<string, any>;
  actions?: (
    refreshCustomerData: (filters?: any) => void
  ) => React.ReactElement;
};
type State = {
  loading: boolean;
  query: string;
  customers: Array<Customer>;
  filteredCustomers: Array<Customer>;
  pagination: Pagination;
};

const DEFAULT_PAGE_SIZE = 10;

class CustomersTableContainer extends React.Component<Props, State> {
  state: State = {
    loading: true,
    query: '',
    customers: [],
    filteredCustomers: [],
    pagination: {
      page_number: 1,
      page_size: DEFAULT_PAGE_SIZE,
    },
  };

  async componentDidMount() {
    await this.handleRefreshCustomers();
  }

  handleRetrieveCustomers = async (
    {page_number: page, page_size: pageSize}: Pagination,
    customFilters = {}
  ) => {
    this.setState({loading: true});

    try {
      const {defaultFilters = {}} = this.props;
      const {data: customers, ...pagination} = await API.fetchCustomers({
        page,
        page_size: pageSize,
        ...customFilters,
        ...defaultFilters,
      });

      this.setState({customers, pagination, loading: false});
    } catch (err) {
      logger.error('Error retrieving customers!', err);

      this.setState({loading: false});
    }
  };

  handleRefreshCustomers = async (filters = {}) => {
    const {pagination} = this.state;

    return this.handleRetrieveCustomers(pagination, filters);
  };

  handlePageChange = async (page: number, pageSize = DEFAULT_PAGE_SIZE) => {
    return this.handleRetrieveCustomers({
      page_number: page,
      page_size: pageSize,
    });
  };

  handleSearchCustomers = (query: string) => {
    const {customers = []} = this.state;

    if (!query || !query.length) {
      this.setState({query: '', filteredCustomers: customers});
    }

    this.setState({query});
  };

  render() {
    const {currentlyOnline, actions} = this.props;
    const {loading, customers, pagination} = this.state;

    return (
      <Box>
        {actions && typeof actions === 'function' && (
          <Flex mb={3} sx={{justifyContent: 'space-between'}}>
            {/* TODO: this will be where we put our search box and other filters */}
            <Box />

            {/* 
              NB: this is where we allow passing in custom action components, 
              e.g. a button for creating a new customer, adding a customer to a tag, etc.
            */}
            {actions(this.handleRefreshCustomers)}
          </Flex>
        )}

        <CustomersTable
          loading={loading}
          customers={customers}
          currentlyOnline={currentlyOnline}
          shouldIncludeAnonymous
          pagination={{
            total: pagination.total_entries,
            onChange: this.handlePageChange,
          }}
          action={(customer: Customer) => (
            <Link to={`/customers/${customer.id}`}>
              <Button>View profile</Button>
            </Link>
          )}
          onUpdate={this.handleRefreshCustomers}
        />
      </Box>
    );
  }
}

export default CustomersTableContainer;
