import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Alert, Paragraph, Text, Title} from '../common';
import {useConversations} from '../conversations/ConversationsProvider';
import * as API from '../../api';
import Spinner from '../Spinner';
import CustomersTable from './CustomersTable';
import logger from '../../logger';

type Props = {
  currentlyOnline?: any;
};
type State = {
  loading: boolean;
  selectedCustomerId: string | null;
  customers: Array<any>;
};

class CustomersPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    selectedCustomerId: null,
    customers: [],
  };

  async componentDidMount() {
    try {
      const customers = await API.fetchCustomers();

      this.setState({customers, loading: false});
    } catch (err) {
      logger.error('Error loading customers!', err);

      this.setState({loading: false});
    }
  }

  render() {
    const {currentlyOnline} = this.props;
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

          <CustomersTable
            customers={customers}
            currentlyOnline={currentlyOnline}
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
