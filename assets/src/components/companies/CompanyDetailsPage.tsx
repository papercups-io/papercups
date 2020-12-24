import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Result, Title} from '../common';
import * as API from '../../api';
import Spinner from '../Spinner';
import logger from '../../logger';

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  company: any;
};

class CompanyDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    company: null,
  };

  async componentDidMount() {
    try {
      const {id: companyId} = this.props.match.params;
      const company = await API.fetchCompany(companyId);
      logger.info('Company:', company); // TODO

      this.setState({company, loading: false});
    } catch (err) {
      logger.error('Error loading company!', err);

      this.setState({loading: false});
    }
  }

  render() {
    const {loading, company} = this.state;

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
        <Title level={3}>{name}</Title>
      </Box>
    );
  }
}

export default CompanyDetailsPage;
