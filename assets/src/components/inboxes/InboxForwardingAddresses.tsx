import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {Alert, Button, Popconfirm, Table, Text, Title} from '../common';
import * as API from '../../api';
import {Account, ForwardingAddress, Inbox} from '../../types';
import logger from '../../logger';
import {NewForwardingAddressModalButton} from '../settings/NewForwardingAddressModal';

const ForwardingAddressesTable = ({
  loading,
  forwardingAddresses,
  onDeleteForwardingAddress,
}: {
  loading?: boolean;
  forwardingAddresses: Array<ForwardingAddress>;
  onDeleteForwardingAddress: (id: string) => void;
}) => {
  const data = forwardingAddresses
    .map((forwardingAddresse) => {
      return {key: forwardingAddresse.id, ...forwardingAddresse};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Forwarding address',
      dataIndex: 'forwarding_email_address',
      key: 'forwarding_email_address',
      render: (value: string) => {
        return (
          <a href={`mailto:${value}?Subject=Papercups test email`}>{value}</a>
        );
      },
    },
    {
      title: 'Source',
      dataIndex: 'source_email_address',
      key: 'source_email_address',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: ForwardingAddress) => {
        return (
          <Flex mx={-1} sx={{justifyContent: 'flex-end'}}>
            {/* 
            TODO: implement me!

            <Box mx={1}>
              <Button>Edit</Button>
            </Box> 
            */}

            <Box mx={1}>
              <Popconfirm
                title="Are you sure you want to delete this forwarding address?"
                okText="Yes"
                cancelText="No"
                placement="topLeft"
                onConfirm={() => onDeleteForwardingAddress(record.id)}
              >
                <Button danger>Delete</Button>
              </Popconfirm>
            </Box>
          </Flex>
        );
      },
    },
  ];

  return <Table loading={loading} dataSource={data} columns={columns} />;
};

const filterForwardingAddressesByQuery = (
  forwardingAddresses: Array<ForwardingAddress>,
  query?: string
): Array<ForwardingAddress> => {
  if (!query || !query.length) {
    return forwardingAddresses;
  }

  return forwardingAddresses.filter((forwardingAddress) => {
    const {
      id,
      description,
      state,
      forwarding_email_address: forwardingEmailAddress,
      source_email_address: sourceEmailAddress,
    } = forwardingAddress;

    const words = [
      id,
      state,
      description,
      forwardingEmailAddress,
      sourceEmailAddress,
    ]
      .filter((str) => str && String(str).trim().length > 0)
      .join(' ')
      .replace('_', ' ')
      .split(' ')
      .map((str) => str.toLowerCase());

    const queries = query.split(' ').map((str) => str.toLowerCase());

    return queries.every((q) => {
      return words.some((word) => word.indexOf(q) !== -1);
    });
  });
};

type Props = {inbox: Inbox};
type State = {
  account: Account | null;
  filterQuery: string;
  filteredForwardingAddresses: Array<ForwardingAddress>;
  isNewForwardingAddressModalVisible: boolean;
  loading: boolean;
  forwardingAddresses: Array<ForwardingAddress>;
};

class InboxForwardingAddresses extends React.Component<Props, State> {
  state: State = {
    account: null,
    filteredForwardingAddresses: [],
    filterQuery: '',
    isNewForwardingAddressModalVisible: false,
    loading: true,
    forwardingAddresses: [],
  };

  async componentDidMount() {
    this.setState({account: await API.fetchAccountInfo()});

    await this.handleRefreshForwardingAddresses();
  }

  handleSearchForwardingAddresses = (filterQuery: string) => {
    const {forwardingAddresses = []} = this.state;

    if (!filterQuery?.length) {
      this.setState({
        filterQuery: '',
        filteredForwardingAddresses: forwardingAddresses,
      });
    }

    this.setState({
      filterQuery,
      filteredForwardingAddresses: filterForwardingAddressesByQuery(
        forwardingAddresses,
        filterQuery
      ),
    });
  };

  handleRefreshForwardingAddresses = async () => {
    try {
      const {filterQuery} = this.state;
      const {id: inboxId} = this.props.inbox;
      const forwardingAddresses = await API.fetchForwardingAddresses({
        inbox_id: inboxId,
      });

      this.setState({
        filteredForwardingAddresses: filterForwardingAddressesByQuery(
          forwardingAddresses,
          filterQuery
        ),
        loading: false,
        forwardingAddresses,
      });
    } catch (err) {
      logger.error('Error loading forwarding addresses!', err);

      this.setState({loading: false});
    }
  };

  handleDeleteForwardingAddress = async (id: string) => {
    try {
      this.setState({loading: true});

      await API.deleteForwardingAddress(id);
      await this.handleRefreshForwardingAddresses();
    } catch (err) {
      logger.error('Error deleting forwarding addresses!', err);

      this.setState({loading: false});
    }
  };

  isOnStarterPlan = () => {
    const {account} = this.state;

    if (!account) {
      return false;
    }

    return account.subscription_plan === 'starter';
  };

  render() {
    const {id: inboxId} = this.props.inbox;
    const {loading, filteredForwardingAddresses = []} = this.state;

    return (
      <Box>
        {this.isOnStarterPlan() && (
          <Box mb={3}>
            <Alert
              message={
                <Text>
                  Email forwarding will only be available on the Lite and Team
                  subscription plans.{' '}
                  <Link to="billing">Sign up for a free trial!</Link>
                </Text>
              }
              type="warning"
              showIcon
            />
          </Box>
        )}

        <Flex
          px={3}
          mb={3}
          sx={{justifyContent: 'space-between', alignItems: 'center'}}
        >
          <Title level={4}>Email forwarding</Title>

          <NewForwardingAddressModalButton
            inboxId={inboxId}
            onSuccess={this.handleRefreshForwardingAddresses}
          >
            New
          </NewForwardingAddressModalButton>
        </Flex>

        <Box my={3}>
          <ForwardingAddressesTable
            loading={loading}
            forwardingAddresses={filteredForwardingAddresses}
            onDeleteForwardingAddress={this.handleDeleteForwardingAddress}
          />
        </Box>
      </Box>
    );
  }
}

export default InboxForwardingAddresses;
