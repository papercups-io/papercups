import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {BrowserSession, Customer} from '../../types';
import Spinner from '../Spinner';
import logger from '../../logger';
import CustomerDetailsSidebar from './CustomerDetailsSidebar';
import EditCustomerDetailsModal from './EditCustomerDetailsModal';
import CustomerDetailsMainSection from './CustomerDetailsMainSection';

type Props = RouteComponentProps<{id: string}>;
type State = {
  customer: Customer | null;
  loading?: boolean;
  session: BrowserSession | null;
  isEditModalVisible: boolean;
};

class CustomerDetailsPage extends React.Component<Props, State> {
  state: State = {
    customer: null,
    loading: true,
    session: null,
    isEditModalVisible: false,
  };

  async componentDidMount() {
    try {
      const [customer, session] = await Promise.all([
        this.fetchCustomer(),
        this.fetchSession(),
      ]);

      this.setState({customer, session, loading: false});
    } catch (err) {
      logger.error('Error loading customer!', err);

      this.setState({loading: false});
    }
  }

  getCustomerId = () => this.props.match.params.id;

  fetchCustomer = async () => {
    return await API.fetchCustomer(this.getCustomerId(), {
      expand: ['company', 'tags'],
    });
  };

  fetchSession = async () => {
    const sessions = await API.fetchBrowserSessions({
      customerId: this.getCustomerId(),
      isActive: true,
      limit: 1,
    });
    const session = sessions[0];

    return session;
  };

  handleCustomerUpdated = async () => {
    const customer = await this.fetchCustomer();
    this.setState({customer});
    this.handleCloseEditModal();
  };

  handleOpenEditModal = () => this.setState({isEditModalVisible: true});
  handleCloseEditModal = () => this.setState({isEditModalVisible: false});

  render() {
    const {history} = this.props;
    const {customer, isEditModalVisible, loading, session} = this.state;

    // TODO: add error handling when customer can't be loaded
    if (loading || !customer) {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
            bg: 'rgb(250, 250, 250)',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    }

    const {title} = customer;

    return (
      <Flex
        p={4}
        sx={{
          flexDirection: 'column',
          flex: 1,
          bg: 'rgb(250, 250, 250)',
        }}
      >
        <Flex mb={4}>
          <Link to="/customers">
            <Button icon={<ArrowLeftOutlined />}>Back to customers</Button>
          </Link>
        </Flex>

        <Box>
          <Flex sx={{justifyContent: 'space-between'}}>
            <Box mx={3}>
              <Title level={3}>{title}</Title>
            </Box>
            <Button onClick={this.handleOpenEditModal}>Edit</Button>
          </Flex>

          <EditCustomerDetailsModal
            customer={customer}
            isVisible={isEditModalVisible}
            onClose={this.handleCloseEditModal}
            onUpdate={this.handleCustomerUpdated}
          />

          <Flex>
            <Box mr={3}>
              <CustomerDetailsSidebar customer={customer} session={session} />
            </Box>

            <Box sx={{flex: 3}}>
              <CustomerDetailsMainSection
                customerId={this.getCustomerId()}
                history={history}
              />
            </Box>
          </Flex>
        </Box>
      </Flex>
    );
  }
}

export default CustomerDetailsPage;
