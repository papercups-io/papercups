import React from 'react';
import {Box, Flex} from 'theme-ui';
import * as API from '../../api';
import {Issue} from '../../types';
import {PlusOutlined} from '../icons';
import IssuesTable from '../issues/IssuesTable';
import {NewIssueModalButton} from '../issues/NewIssueModal';
import logger from '../../logger';

type Props = {customerId: string};
type State = {
  issues: Issue[];
  isModalOpen: boolean;
  loading: boolean;
};

class CustomerDetailsIssues extends React.Component<Props, State> {
  state: State = {
    issues: [],
    isModalOpen: false,
    loading: true,
  };

  componentDidMount() {
    this.fetchCustomerIssues();
  }

  fetchCustomerIssues = async () => {
    try {
      const {customerId} = this.props;
      const {issues} = await API.fetchCustomer(customerId, {
        expand: ['issues'],
      });

      this.setState({issues});
    } catch (err) {
      logger.error('Error retrieving issues:', err);
    }

    this.setState({loading: false});
  };

  handleNewIssueLinked = () => {
    this.fetchCustomerIssues();
  };

  render() {
    const {customerId} = this.props;
    const {loading, issues = []} = this.state;

    return (
      <Box>
        <Flex p={3} sx={{justifyContent: 'flex-end'}}>
          <NewIssueModalButton
            type="primary"
            icon={<PlusOutlined />}
            customerId={customerId}
            onSuccess={this.handleNewIssueLinked}
          >
            Link new issue to customer
          </NewIssueModalButton>
        </Flex>

        <IssuesTable
          loading={loading}
          issues={issues}
          onUpdate={this.fetchCustomerIssues}
        />
      </Box>
    );
  }
}

export default CustomerDetailsIssues;
