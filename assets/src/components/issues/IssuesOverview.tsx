import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  Alert,
  Button,
  Divider,
  Input,
  Paragraph,
  Table,
  Tag,
  Text,
  Title,
} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';
import NewIssueModal from './NewIssueModal';

const IssuesTable = ({
  loading,
  issues,
}: {
  loading?: boolean;
  issues: Array<T.Issue>;
}) => {
  const data = issues
    .map((issue) => {
      return {key: issue.id, ...issue};
    })
    .sort((a, b) => {
      return +new Date(b.updated_at) - +new Date(a.updated_at);
    });

  const columns = [
    {
      title: 'Status',
      dataIndex: 'state',
      key: 'state',
      render: (value: string) => {
        switch (value) {
          case 'unstarted':
            return <Tag>unstarted</Tag>;
          case 'in_progress':
            return <Tag color="orange">in progress</Tag>;
          case 'in_review':
            return <Tag color="blue">in review</Tag>;
          case 'done':
            return <Tag color="green">done</Tag>;
          case 'closed':
            return <Tag color="red">closed</Tag>;
          default:
            return <Tag>{value.split('_').join(' ')}</Tag>;
        }
      },
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
      render: (value: string, record: T.Issue) => {
        const {github_issue_url: githubIssueUrl} = record;

        if (githubIssueUrl) {
          return (
            <a href={githubIssueUrl} target="_blank" rel="noopener noreferrer">
              {value}
            </a>
          );
        }

        return <Text>{value}</Text>;
      },
    },
    {
      title: 'Description',
      dataIndex: 'body',
      key: 'body',
      render: (value: string) => {
        return value || '--';
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      render: (value: string, record: any) => {
        // TODO: add after implementing IssueDetailsPage
        return null;
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      pagination={false}
    />
  );
};

type Props = {};
type State = {
  filterQuery: string;
  filteredIssues: Array<T.Issue>;
  isNewIssueModalVisible: boolean;
  loading: boolean;
  issues: Array<T.Issue>;
};

const filterIssuesByQuery = (
  issues: Array<T.Issue>,
  query?: string
): Array<T.Issue> => {
  if (!query || !query.length) {
    return issues;
  }

  return issues.filter((issue) => {
    const {id, title, body} = issue;

    const words = [id, title, body]
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

class IssuesOverview extends React.Component<Props, State> {
  state: State = {
    filteredIssues: [],
    filterQuery: '',
    isNewIssueModalVisible: false,
    loading: true,
    issues: [],
  };

  async componentDidMount() {
    await this.handleRefreshIssues();
  }

  handleSearchIssues = (filterQuery: string) => {
    const {issues = []} = this.state;

    if (!filterQuery?.length) {
      this.setState({filterQuery: '', filteredIssues: issues});
    }

    this.setState({
      filterQuery,
      filteredIssues: filterIssuesByQuery(issues, filterQuery),
    });
  };

  handleRefreshIssues = async () => {
    try {
      const {filterQuery} = this.state;
      const issues = await API.fetchAllIssues();

      this.setState({
        filteredIssues: filterIssuesByQuery(issues, filterQuery),
        loading: false,
        issues,
      });
    } catch (err) {
      logger.error('Error loading issues!', err);

      this.setState({loading: false});
    }
  };

  handleOpenNewIssueModal = () => {
    this.setState({isNewIssueModalVisible: true});
  };

  handleNewIssueModalClosed = () => {
    this.setState({isNewIssueModalVisible: false});
  };

  handleNewIssueCreated = () => {
    this.handleNewIssueModalClosed();
    this.handleRefreshIssues();
  };

  render() {
    const {loading, isNewIssueModalVisible, filteredIssues = []} = this.state;

    return (
      <Box p={4} sx={{maxWidth: 1080}}>
        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={3}>Issues (beta)</Title>

          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={this.handleOpenNewIssueModal}
          >
            New issue
          </Button>
        </Flex>

        <NewIssueModal
          visible={isNewIssueModalVisible}
          onSuccess={this.handleNewIssueCreated}
          onCancel={this.handleNewIssueModalClosed}
        />

        <Box mb={4}>
          <Paragraph>
            Use issues to track and manage feedback from your customers.
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

        <Box mb={3}>
          <Input.Search
            placeholder="Search issues..."
            allowClear
            onSearch={this.handleSearchIssues}
            style={{width: 400}}
          />
        </Box>

        <Divider />

        <Box mb={5}>
          <Title level={4}>Recently done</Title>
          <Paragraph>
            <Text type="secondary">
              These issues are done, but customers have not yet been notified.
            </Text>
          </Paragraph>
          <IssuesTable
            loading={loading}
            issues={filteredIssues.filter(({state}) => state === 'done')}
          />
        </Box>

        <Box mb={5}>
          <Title level={4}>Unfinished</Title>
          <Paragraph>
            <Text type="secondary">
              These issues are still in progress or yet to be started.
            </Text>
          </Paragraph>
          <IssuesTable
            loading={loading}
            issues={filteredIssues.filter(
              ({state}) => state !== 'done' && state !== 'closed'
            )}
          />
        </Box>

        <Box mb={5}>
          <Title level={4}>Closed</Title>
          <Paragraph>
            <Text type="secondary">
              These issues have been finished and customers have been notified.
            </Text>
          </Paragraph>
          <IssuesTable
            loading={loading}
            issues={filteredIssues.filter(({state}) => state === 'closed')}
          />
        </Box>
      </Box>
    );
  }
}

export default IssuesOverview;
