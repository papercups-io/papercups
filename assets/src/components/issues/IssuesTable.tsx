import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Flex} from 'theme-ui';
import {Button, Dropdown, Menu, Table, Tag, Text} from '../common';
import {SettingOutlined} from '../icons';
import * as API from '../../api';
import * as T from '../../types';
import {formatRelativeTime} from '../../utils';

dayjs.extend(utc);

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
      render: (value: string, record: T.Issue) => {
        const {id: issueId} = record;

        return (
          <Link to={`/issues/${issueId}`}>
            <Text>{value}</Text>
          </Link>
        );
      },
    },
    {
      title: 'Last updated',
      dataIndex: 'updated_at',
      key: 'updated_at',
      render: (value: string, record: T.Issue) => {
        const {id: issueId} = record;
        const formatted = formatRelativeTime(dayjs.utc(value));

        return (
          <Link to={`/issues/${issueId}`}>
            <Text>{formatted || '--'}</Text>
          </Link>
        );
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
          <Flex sx={{justifyContent: 'flex-end'}}>
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
          </Flex>
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

export default IssuesTable;
