import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Title} from '../common';
import * as API from '../../api';
import Spinner from '../Spinner';
import logger from '../../logger';

type Props = {};
type State = {
  loading: boolean;
  companies: Array<any>;
};

class CreateCompanyPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    companies: [],
  };

  async componentDidMount() {
    try {
      const companies = await API.fetchCompanies();
      logger.info('Companies:', companies); // TODO

      this.setState({companies, loading: false});
    } catch (err) {
      logger.error('Error loading companies!', err);

      this.setState({loading: false});
    }
  }

  render() {
    const {loading} = this.state;

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
        <Title level={3}>New company (beta)</Title>
      </Box>
    );
  }
}

export default CreateCompanyPage;
