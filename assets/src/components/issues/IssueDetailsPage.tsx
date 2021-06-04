import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Card,
  Divider,
  MarkdownRenderer,
  Popconfirm,
  Result,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined, DeleteOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import {sleep} from '../../utils';
import Spinner from '../Spinner';
import logger from '../../logger';
import CustomersTableContainer from '../customers/CustomersTableContainer';
import {SearchCustomersModalButton} from '../customers/SearchCustomers';
import {IssueStateTag} from './IssuesTable';
import {UpdateIssueModalButton} from './UpdateIssueModal';
import {isValidGithubUrl} from './support';

const formatGithubUrl = (url: string) => {
  const [, githubIssuePath] = url.split('github.com/');

  return githubIssuePath;
};

const DetailsSectionCard = ({children}: {children: any}) => {
  return <Card sx={{p: 3, mb: 3}}>{children}</Card>;
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  deleting: boolean;
  refreshing: boolean;
  isUpdateModalVisible: boolean;
  issue: T.Issue | null;
};

class IssueDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    deleting: false,
    refreshing: false,
    isUpdateModalVisible: false,
    issue: null,
  };

  async componentDidMount() {
    try {
      const issueId = this.getIssueId();
      const issue = await API.fetchIssueById(issueId);

      this.setState({
        issue,
        loading: false,
      });
    } catch (err) {
      logger.error('Error loading issue!', err);

      this.setState({loading: false});
    }
  }

  getIssueId = () => {
    return this.props.match.params.id;
  };

  handleRefreshIssue = async () => {
    this.setState({refreshing: true});

    try {
      const issueId = this.getIssueId();
      const issue = await API.fetchIssueById(issueId);

      this.setState({issue, refreshing: false});
    } catch (err) {
      logger.error('Error refreshing issues!', err);

      this.setState({refreshing: false});
    }
  };

  handleDeleteIssue = async () => {
    try {
      this.setState({deleting: true});
      const issueId = this.getIssueId();

      await API.deleteIssue(issueId);
      await sleep(1000);

      this.props.history.push('/issues');
    } catch (err) {
      logger.error('Error deleting issue!', err);

      this.setState({deleting: false});
    }
  };

  handleOpenUpdateIssueModal = () => {
    this.setState({isUpdateModalVisible: true});
  };

  handleUpdateIssueModalClosed = () => {
    this.setState({isUpdateModalVisible: false});
  };

  handleIssueUpdated = () => {
    this.handleUpdateIssueModalClosed();
    this.handleRefreshIssue();
  };

  handleLinkNewCustomer = (onSuccess: (filters?: any) => any) => (
    customer: T.Customer
  ) => {
    const {id: customerId} = customer;
    const issueId = this.getIssueId();

    if (!customerId) {
      return null;
    }

    return API.addCustomerIssue(customerId, issueId)
      .then(() => onSuccess())
      .catch((err) => logger.error('Error linking issue to customer:', err));
  };

  render() {
    const {loading, deleting, issue} = this.state;

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
    } else if (!issue) {
      return <Result status="error" title="Error retrieving issue" />;
    }

    const {
      title,
      body: description,
      state: status,
      github_issue_url: githubIssueUrl,
    } = issue;

    return (
      <Flex
        p={4}
        sx={{
          flexDirection: 'column',
          flex: 1,
          bg: 'rgb(250, 250, 250)',
        }}
      >
        <Flex
          mb={4}
          sx={{justifyContent: 'space-between', alignItems: 'center'}}
        >
          <Link to="/issues">
            <Button icon={<ArrowLeftOutlined />}>Back to all issues</Button>
          </Link>

          <Popconfirm
            title="Are you sure you want to delete this issue?"
            okText="Yes"
            cancelText="No"
            placement="bottomLeft"
            onConfirm={this.handleDeleteIssue}
          >
            <Button danger loading={deleting} icon={<DeleteOutlined />}>
              Delete issue
            </Button>
          </Popconfirm>
        </Flex>

        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={2}>{title || 'Issue details'}</Title>

          <UpdateIssueModalButton
            type="default"
            issue={issue}
            onSuccess={this.handleRefreshIssue}
          >
            Edit
          </UpdateIssueModalButton>
        </Flex>

        <Flex>
          <Box sx={{flex: 1, pr: 4}}>
            {/* TODO: style the issue details similar to GitHub? */}
            <DetailsSectionCard>
              <MarkdownRenderer source={description || '_No description_'} />

              <Divider />

              <Box mb={3}>
                <Box>
                  <Text strong>Status</Text>
                </Box>

                <IssueStateTag state={status} />
              </Box>

              {!!githubIssueUrl && isValidGithubUrl(githubIssueUrl) && (
                <Box mb={3}>
                  <Box>
                    <Text strong>GitHub URL</Text>
                  </Box>

                  <a
                    href={githubIssueUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {formatGithubUrl(githubIssueUrl)}
                  </a>
                </Box>
              )}
            </DetailsSectionCard>
          </Box>

          <Box sx={{flex: 2}}>
            <DetailsSectionCard>
              <Flex
                mb={3}
                sx={{
                  justifyContent: 'space-between',
                  borderBottom: '1px solid rgba(0,0,0,.06)',
                }}
              >
                <Title level={4}>People</Title>
              </Flex>

              <CustomersTableContainer
                defaultFilters={{issue_id: this.getIssueId()}}
                actions={(handleRefreshCustomers) => (
                  <SearchCustomersModalButton
                    modal={{title: 'Link customer to issue'}}
                    onSuccess={this.handleLinkNewCustomer(
                      handleRefreshCustomers
                    )}
                  >
                    Link new customer to issue
                  </SearchCustomersModalButton>
                )}
              />
            </DetailsSectionCard>
          </Box>
        </Flex>
      </Flex>
    );
  }
}

export default IssueDetailsPage;
