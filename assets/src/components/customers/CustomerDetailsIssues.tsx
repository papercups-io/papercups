import React from 'react';
import * as API from '../../api';
import {Issue} from '../../types';
import {IssuesTable} from '../issues/IssuesOverview';
import logger from '../../logger';

type Props = {customerId: string};
type State = {
  issues: Issue[];
  loading: boolean;
};

class CustomerDetailsIssues extends React.Component<Props, State> {
  state: State = {
    issues: [],
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

  render() {
    const {loading, issues} = this.state;

    return <IssuesTable loading={loading} issues={issues} />;
  }
}

export default CustomerDetailsIssues;
