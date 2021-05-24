import React from 'react';
import {Box, Flex} from 'theme-ui';
import {debounce} from 'lodash';
import {Checkbox, Input} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {Customer, Pagination} from '../../types';
import CustomersTable from './CustomersTable';
import CustomerTagSelect from './CustomerTagSelect';

type Props = {
  currentlyOnline?: any;
  shouldIncludeAnonymous?: boolean;
  defaultFilters?: Record<string, any>;
  includeSearchInput?: boolean;
  includeTagFilterInput?: boolean;
  includeAnonymousUserFilter?: boolean;
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
  selectedTagIds: string[];
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
      selectedTagIds: [],
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
      const {selectedTagIds, shouldIncludeAnonymous} = this.state;
      const {data: customers, ...pagination} = await API.fetchCustomers({
        page,
        page_size: pageSize,
        include_anonymous: shouldIncludeAnonymous,
        tag_ids: selectedTagIds,
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

  handleTagsSelect = (selectedTagIds: string[]) => {
    this.setState({selectedTagIds}, () => this.handleRefreshCustomers());
  };

  render() {
    const {
      currentlyOnline,
      includeSearchInput = true,
      includeTagFilterInput = false,
      includeAnonymousUserFilter = true,
      actions,
    } = this.props;
    const {loading, customers, pagination, shouldIncludeAnonymous} = this.state;

    return (
      <Box>
        {actions && typeof actions === 'function' && (
          <Flex mb={3} sx={{justifyContent: 'space-between'}}>
            {/* TODO: this will be where we put our search box and other filters */}
            <Flex mx={-2} sx={{alignItems: 'center'}}>
              {includeSearchInput && (
                <Box mx={2}>
                  <Input.Search
                    placeholder="Search customers..."
                    allowClear
                    onSearch={this.handleSearchCustomers}
                    style={{width: 280}}
                  />
                </Box>
              )}
              {includeTagFilterInput && (
                <Box ml={2} mr={3}>
                  <CustomerTagSelect
                    placeholder="Filter by tags"
                    onChange={this.handleTagsSelect}
                    style={{width: 280}}
                  />
                </Box>
              )}
              {includeAnonymousUserFilter && (
                <Checkbox
                  checked={shouldIncludeAnonymous}
                  onChange={this.handleToggleIncludeAnonymous}
                >
                  Include anonymous
                </Checkbox>
              )}
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
