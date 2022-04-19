import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';

import {
  Alert,
  Button,
  Container,
  Input,
  Paragraph,
  Popconfirm,
  Table,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {Account, ForwardingAddress, Inbox} from '../../types';
import {NewForwardingAddressModalButton} from '../settings/NewForwardingAddressModal';
import logger from '../../logger';

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

type Props = RouteComponentProps<{inbox_id: string}>;
type State = {
  account: Account | null;
  inbox: Inbox | null;
  filterQuery: string;
  filteredForwardingAddresses: Array<ForwardingAddress>;
  isNewForwardingAddressModalVisible: boolean;
  loading: boolean;
  forwardingAddresses: Array<ForwardingAddress>;
};

class InboxEmailForwardingPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    account: null,
    inbox: null,
    filteredForwardingAddresses: [],
    filterQuery: '',
    isNewForwardingAddressModalVisible: false,
    forwardingAddresses: [],
  };

  async componentDidMount() {
    const {inbox_id: inboxId} = this.props.match.params;

    this.setState({
      account: await API.fetchAccountInfo(),
      inbox: await API.fetchInbox(inboxId),
    });

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
      const {inbox_id: inboxId} = this.props.match.params;
      const {filterQuery} = this.state;
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
    const {inbox_id: inboxId} = this.props.match.params;
    const {loading, filteredForwardingAddresses = [], inbox} = this.state;

    return (
      <Container sx={{maxWidth: 800}}>
        <Box mb={4}>
          <Link to={`/inboxes/${inboxId}`}>
            <Button icon={<ArrowLeftOutlined />}>
              Back to {inbox?.name || 'inbox'}
            </Button>
          </Link>
        </Box>
        {this.isOnStarterPlan() && (
          <Box mb={4}>
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
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Email forwarding</Title>

          <NewForwardingAddressModalButton
            inboxId={inboxId}
            onSuccess={this.handleRefreshForwardingAddresses}
          >
            New
          </NewForwardingAddressModalButton>
        </Flex>

        <Box mb={4}>
          <Paragraph>
            Use forwarding email addresses to forward messages into{' '}
            {inbox ? `the ${inbox.name}` : 'Papercups'}.
          </Paragraph>
        </Box>

        <Box mb={3}>
          <Input.Search
            placeholder="Search forwarding addresses..."
            allowClear
            onSearch={this.handleSearchForwardingAddresses}
            style={{width: 400}}
          />
        </Box>

        <Box my={4}>
          <ForwardingAddressesTable
            loading={loading}
            forwardingAddresses={filteredForwardingAddresses}
            onDeleteForwardingAddress={this.handleDeleteForwardingAddress}
          />
        </Box>
      </Container>
    );
  }
}

export default InboxEmailForwardingPage;
