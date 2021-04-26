import React from 'react';
import {Box, Flex} from 'theme-ui';
import * as API from '../../api';
import {Issue} from '../../types';
import {Button} from '../common';
import {PlusOutlined} from '../icons';
import {IssuesTable} from '../issues/IssuesOverview';
import {NewIssueModalButton} from '../issues/NewIssueModal';
import SearchIssuesInput from '../issues/SearchIssuesInput';
import logger from '../../logger';

type Props = {customerId: string};
type State = {
  issues: Issue[];
  selectedIssueId: string | undefined;
  selectedIssueTitle: string | undefined;
  isModalOpen: boolean;
  loading: boolean;
};

class CustomerDetailsIssues extends React.Component<Props, State> {
  state: State = {
    issues: [],
    selectedIssueId: undefined,
    selectedIssueTitle: undefined,
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

  handleChangeQuery = (title: string, record: any) => {
    const {key: selectedIssueId} = record;

    this.setState({selectedIssueId, selectedIssueTitle: title});
  };

  handleSelectIssue = ({id, title}: Issue) => {
    this.setState({selectedIssueId: id, selectedIssueTitle: title});
  };

  handleLinkIssue = async () => {
    const {customerId} = this.props;
    const {selectedIssueId} = this.state;

    if (!selectedIssueId) {
      return null;
    }

    return API.addCustomerIssue(customerId, selectedIssueId)
      .then(() => this.fetchCustomerIssues())
      .then(() =>
        this.setState({
          selectedIssueId: '',
          selectedIssueTitle: '',
        })
      )
      .catch((err) => logger.error('Error linking issue to customer:', err));
  };

  handleNewIssueCreated = () => {
    this.fetchCustomerIssues();
  };

  render() {
    const {customerId} = this.props;
    const {loading, issues, selectedIssueId, selectedIssueTitle} = this.state;

    return (
      <Box>
        <Flex p={3}>
          <Box sx={{flex: 1}}>
            <SearchIssuesInput
              value={selectedIssueTitle}
              ignored={issues}
              onChange={this.handleChangeQuery}
              onSelectIssue={this.handleSelectIssue}
            />
          </Box>
          <Box ml={1}>
            <Button
              type="primary"
              onClick={this.handleLinkIssue}
              disabled={!selectedIssueId}
            >
              Link issue
            </Button>
          </Box>

          <Box ml={3} pl={3} style={{borderLeft: '1px solid rgba(0,0,0,.06)'}}>
            <NewIssueModalButton
              type="primary"
              icon={<PlusOutlined />}
              disabled={!!selectedIssueId}
              customerId={customerId}
              onSuccess={this.handleNewIssueCreated}
            >
              Create new issue
            </NewIssueModalButton>
          </Box>
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
