import React from 'react';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import {Checkbox, Input} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {Customer, Pagination} from '../../types';
import CustomersTable from './CustomersTable';

type Props = {
  currentlyOnline?: any;
  shouldIncludeAnonymous?: boolean;
  defaultFilters?: Record<string, any>;
  actions?: (
    refreshCustomerData: (filters?: any) => void
  ) => React.ReactElement;
};
type State = {
  loading: boolean;
  query: string;
  customers: Array<Customer>;
  shouldIncludeAnonymous: boolean;
  pagination: Pagination;
};

const DEFAULT_PAGE_SIZE = 10;

class CustomersTableContainer extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    // If undefined, default to `true`
    const {shouldIncludeAnonymous = true} = props;

    this.state = {
      loading: true,
      query: '',
      customers: [],
      shouldIncludeAnonymous,
      pagination: {
        page_number: 1,
        page_size: DEFAULT_PAGE_SIZE,
      },
    };
  }

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
      const {shouldIncludeAnonymous} = this.state;
      const {data: customers, ...pagination} = await API.fetchCustomers({
        page,
        page_size: pageSize,
        include_anonymous: shouldIncludeAnonymous,
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

  handleToggleIncludeAnonymous = (e: any) => {
    this.setState({shouldIncludeAnonymous: e.target.checked}, () =>
      this.handleRefreshCustomers()
    );
  };

  handleSearchCustomers = (query: string) => {
    this.setState({query}, () => this.debouncedFilterCustomersByQuery());
  };

  debouncedFilterCustomersByQuery = debounce(() => {
    const {query = ''} = this.state;

    this.handleRefreshCustomers({q: query});
  }, 200);

  render() {
    const {currentlyOnline, actions} = this.props;
    const {loading, customers, pagination, shouldIncludeAnonymous} = this.state;

    return (
      <Box>
        {actions && typeof actions === 'function' && (
          <Flex mb={3} sx={{justifyContent: 'space-between'}}>
            {/* TODO: this will be where we put our search box and other filters */}
            <Flex mx={-2} sx={{alignItems: 'center'}}>
              <Box mx={2}>
                <Input.Search
                  placeholder="Search customers..."
                  allowClear
                  onSearch={this.handleSearchCustomers}
                  style={{width: 320}}
                />
              </Box>

              <Box mx={2}>
                <Checkbox
                  checked={shouldIncludeAnonymous}
                  onChange={this.handleToggleIncludeAnonymous}
                >
                  Include anonymous
                </Checkbox>
              </Box>
            </Flex>

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
          onUpdate={this.handleRefreshCustomers}
        />
      </Box>
    );
  }
}

export default CustomersTableContainer;
