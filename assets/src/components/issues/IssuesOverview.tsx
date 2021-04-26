import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  Alert,
  Button,
  Divider,
  Dropdown,
  Input,
  Menu,
  Paragraph,
  Table,
  Tag,
  Text,
  Title,
} from '../common';
import {PlusOutlined, SettingOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import logger from '../../logger';
import NewIssueModal from './NewIssueModal';

export const IssueStateTag = ({state}: {state: T.IssueState}) => {
  switch (state) {
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
      return <Tag>{state}</Tag>;
  }
};

export const IssuesTable = ({
  loading,
  issues,
  onUpdate,
}: {
  loading?: boolean;
  issues: Array<T.Issue>;
  onUpdate: () => void;
}) => {
  const handleUpdateState = async (id: string, state: T.IssueState) => {
    return API.updateIssue(id, {state}).then(() => onUpdate());
  };

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
      render: (value: T.IssueState) => {
        return <IssueStateTag state={value} />;
      },
    },
    {
      title: 'Title',
      dataIndex: 'title',
      key: 'title',
      render: (value: string) => {
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
      render: (value: string, record: T.Issue) => {
        const {id: issueId, github_issue_url: githubIssueUrl, state} = record;
        const handleMenuClick = (data: any) => {
          switch (data.key) {
            case 'done':
              return handleUpdateState(issueId, 'done');
            case 'closed':
              return handleUpdateState(issueId, 'closed');
            case 'unstarted':
              return handleUpdateState(issueId, 'unstarted');
            default:
              return null;
          }
        };

        return (
          <Dropdown
            overlay={
              <Menu onClick={handleMenuClick}>
                <Menu.Item key="info">
                  <Link to={`/issues/${issueId}`}>View details</Link>
                </Menu.Item>
                {!!githubIssueUrl && (
                  <Menu.Item key="github">
                    <a
                      href={githubIssueUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      View on GitHub
                    </a>
                  </Menu.Item>
                )}
                {state !== 'done' && (
                  <Menu.Item key="done">Move to done</Menu.Item>
                )}
                {state !== 'closed' && (
                  <Menu.Item key="closed">Move to closed</Menu.Item>
                )}
                {state !== 'unstarted' && state !== 'in_progress' && (
                  <Menu.Item key="unstarted">Move to unstarted</Menu.Item>
                )}
              </Menu>
            }
          >
            <Button icon={<SettingOutlined />} />
          </Dropdown>
        );
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
            onUpdate={this.handleRefreshIssues}
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
            onUpdate={this.handleRefreshIssues}
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
            onUpdate={this.handleRefreshIssues}
          />
        </Box>
      </Box>
    );
  }
}

export default IssuesOverview;
