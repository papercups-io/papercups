import React from 'react';
import {Box} from 'theme-ui';
import {capitalize} from 'lodash';
import {ButtonProps} from 'antd/lib/button';
import {Button, Input, Modal, Select, Text, TextArea} from '../common';
import * as API from '../../api';
import {Issue, IssueState} from '../../types';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const UpdateIssueModal = ({
  visible,
  issue,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  issue: Issue;
  onSuccess: (params: any) => void;
  onCancel: () => void;
}) => {
  const [title, setTitle] = React.useState(issue.title ?? '');
  const [body, setBody] = React.useState(issue.body ?? '');
  const [githubIssueUrl, setGithubIssueUrl] = React.useState(
    issue.github_issue_url ?? ''
  );
  const [status, setStatus] = React.useState<IssueState>(issue.state ?? '');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  const handleChangeTitle = (e: any) => setTitle(e.target.value);
  const handleChangeBody = (e: any) => setBody(e.target.value);
  const handleChangeGithubIssueUrl = (e: any) =>
    setGithubIssueUrl(e.target.value);

  const resetInputFields = () => {
    setTitle(issue.title ?? '');
    setBody(issue.body ?? '');
    setGithubIssueUrl(issue.github_issue_url ?? '');
    setStatus(issue.state ?? '');
    setErrorMessage(null);
  };

  const handleCancelIssue = () => {
    onCancel();

    setTimeout(() => resetInputFields(), 400);
  };

  const handleUpdateIssue = async () => {
    setIsSaving(true);

    try {
      const result = await API.updateIssue(issue.id, {
        title,
        body,
        github_issue_url: githubIssueUrl,
        state: status,
      });

      onSuccess(result);
    } catch (err) {
      logger.error('Error creating issue:', err);
      const errorMessage = formatServerError(err);
      setErrorMessage(errorMessage);
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal
      title="Update issue"
      visible={visible}
      width={400}
      onOk={handleUpdateIssue}
      onCancel={handleCancelIssue}
      footer={[
        <Button key="cancel" onClick={handleCancelIssue}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleUpdateIssue}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="title">Title</label>
          <Input
            id="title"
            type="text"
            value={title}
            onChange={handleChangeTitle}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="body">Description</label>
          <TextArea
            id="body"
            placeholder="Optional"
            value={body}
            onChange={handleChangeBody}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="github_issue_url">GitHub Issue URL</label>
          <Input
            id="github_issue_url"
            type="text"
            placeholder="https://github.com/my/repo/issues/123"
            value={githubIssueUrl}
            onChange={handleChangeGithubIssueUrl}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="state">Status</label>
          <Box>
            <Select
              style={{width: '100%'}}
              value={status}
              onChange={setStatus}
              options={[
                'unstarted',
                'in_progress',
                'in_review',
                'done',
                'closed',
              ].map((value: string) => {
                const formatted = value.split('_').join(' ');

                return {value, label: capitalize(formatted)};
              })}
            />
          </Box>
        </Box>

        {error && (
          <Box mb={-3}>
            <Text type="danger">{error}</Text>
          </Box>
        )}
      </Box>
    </Modal>
  );
};

type CommonProps = {
  issue: Issue;
  onSuccess: (data: Issue) => void;
};

export const UpdateIssueModalButton = ({
  issue,
  onSuccess,
  ...props
}: CommonProps & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = (issue: Issue) => {
    handleCloseModal();
    onSuccess(issue);
  };

  return (
    <>
      <Button type="primary" {...props} onClick={handleOpenModal} />
      <UpdateIssueModal
        visible={isModalOpen}
        issue={issue}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};

export default UpdateIssueModal;
