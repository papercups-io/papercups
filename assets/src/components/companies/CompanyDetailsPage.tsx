import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Result, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import Spinner from '../Spinner';
import logger from '../../logger';
import CustomersTable from '../customers/CustomersTable';

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  company: any;
  customers: Array<any>;
};

class CompanyDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    company: null,
    customers: [],
  };

  async componentDidMount() {
    try {
      const {id: companyId} = this.props.match.params;
      const company = await API.fetchCompany(companyId);
      const customers = await API.fetchCustomers({company_id: companyId});
      logger.info({company, customers}); // TODO

      this.setState({company, customers, loading: false});
    } catch (err) {
      logger.error('Error loading company!', err);

      this.setState({loading: false});
    }
  }

  render() {
    const {loading, company, customers = []} = this.state;

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
    } else if (!company) {
      return <Result status="error" title="Error retrieving company" />;
    }

    const {name} = company;

    return (
      <Box p={4}>
        <Box mb={4}>
          <Link to="/companies">
            <Button icon={<ArrowLeftOutlined />}>Back to companies</Button>
          </Link>
        </Box>

        <Title level={3}>{name}</Title>

        <Box my={4}>
          <CustomersTable
            loading={loading}
            customers={customers}
            currentlyOnline={{}}
            onUpdate={() => Promise.resolve()}
          />
        </Box>
      </Box>
    );
  }
}

export default CompanyDetailsPage;
