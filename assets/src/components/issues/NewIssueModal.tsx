import React from 'react';
import {Box} from 'theme-ui';
import {capitalize} from 'lodash';
import {ButtonProps} from 'antd/lib/button';
import {Button, Input, Modal, Select, Text, TextArea} from '../common';
import * as API from '../../api';
import {Issue, IssueState} from '../../types';
import logger from '../../logger';
import {formatServerError} from '../../utils';
import Paragraph from 'antd/lib/typography/Paragraph';
import SearchIssuesInput from './SearchIssuesInput';
import {isValidGithubIssueUrl} from './support';

const parseGithubState = (state: string): IssueState => {
  switch (state) {
    case 'open':
      return 'unstarted';
    case 'closed':
      return 'done';
    default:
      return 'unstarted';
  }
};

const NewIssueModal = ({
  visible,
  header,
  customerId,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  header?: string;
  customerId?: string;
  onSuccess: (issue: Issue) => void;
  onCancel: () => void;
}) => {
  const DEFAULT_ISSUE_STATE: IssueState = 'unstarted';

  const [query, setQuery] = React.useState('');
  const [
    selectedExistingIssue,
    setSelectedExistingIssue,
  ] = React.useState<Issue | null>(null);

  const [title, setTitle] = React.useState('');
  const [body, setBody] = React.useState('');
  const [githubIssueUrl, setGithubIssueUrl] = React.useState('');
  const [status, setStatus] = React.useState<IssueState>(DEFAULT_ISSUE_STATE);

  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);
  const [isSyncing, setIsSyncing] = React.useState(false);

  const fallbackModalTitle = customerId
    ? 'Link issue to customer'
    : 'Create new issue';

  const handleChangeTitle = (e: any) => setTitle(e.target.value);
  const handleChangeBody = (e: any) => setBody(e.target.value);
  const handleChangeGithubIssueUrl = (e: any) =>
    setGithubIssueUrl(e.target.value);

  const syncWithGithub = async () => {
    setIsSyncing(true);

    try {
      const [issue] = await API.findGithubIssues({url: githubIssueUrl});
      const {
        title: githubIssueTitle,
        body: githubIssueBody,
        state: githubIssueState,
      } = issue;

      setTitle(githubIssueTitle);
      setBody(githubIssueBody);
      setStatus(parseGithubState(githubIssueState));
    } catch (err) {
      logger.error('Error syncing GitHub issue:', err);
    }

    setIsSyncing(false);
  };

  const handleLinkExistingIssue = async () => {
    const issueId = selectedExistingIssue?.id;

    if (!selectedExistingIssue || !issueId || !customerId) {
      return;
    }

    setIsSaving(true);

    try {
      await API.addCustomerIssue(customerId, issueId);

      onSuccess(selectedExistingIssue);
      resetInputFields();
    } catch (err) {
      logger.error('Error creating issue:', err);
      const errorMessage = formatServerError(err);
      setErrorMessage(errorMessage);
    } finally {
      setIsSaving(false);
    }
  };

  const resetInputFields = () => {
    setTitle('');
    setBody('');
    setGithubIssueUrl('');
    setStatus(DEFAULT_ISSUE_STATE);
    setQuery('');
    setSelectedExistingIssue(null);
    setErrorMessage(null);
  };

  const handleCancelIssue = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateIssue = async () => {
    setIsSaving(true);

    if (!title && selectedExistingIssue) {
      return handleLinkExistingIssue();
    }

    try {
      const issue = await API.createIssue({
        title,
        body,
        github_issue_url: githubIssueUrl,
        state: status,
      });

      if (customerId) {
        const {id: issueId} = issue;

        await API.addCustomerIssue(customerId, issueId);
      }

      onSuccess(issue);
      resetInputFields();
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
      title={header || fallbackModalTitle}
      visible={visible}
      width={400}
      onOk={handleCreateIssue}
      onCancel={handleCancelIssue}
      footer={[
        <Button key="cancel" onClick={handleCancelIssue}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateIssue}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        {!!customerId && (
          <>
            <Box pb={3} mb={3} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
              <Box mb={2}>
                <SearchIssuesInput
                  value={query}
                  onChange={setQuery}
                  onSelectIssue={setSelectedExistingIssue}
                />
              </Box>
              <Button
                type="primary"
                block
                disabled={!selectedExistingIssue}
                loading={isSaving}
                onClick={handleLinkExistingIssue}
              >
                Link existing issue
              </Button>
            </Box>

            <Paragraph>
              <Text type="secondary">Or, sync a GitHub issue...</Text>
            </Paragraph>
          </>
        )}

        <Box pb={3} mb={3} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
          <Box mb={2}>
            <label htmlFor="github_issue_url">GitHub Issue URL</label>
            <Input
              id="github_issue_url"
              type="text"
              placeholder="https://github.com/my/repo/issues/123"
              value={githubIssueUrl}
              onChange={handleChangeGithubIssueUrl}
            />
          </Box>
          <Button
            type="primary"
            disabled={!isValidGithubIssueUrl(githubIssueUrl)}
            loading={isSyncing}
            block
            onClick={syncWithGithub}
          >
            Sync from GitHub
          </Button>
        </Box>

        <Paragraph>
          <Text type="secondary">Or, create manually...</Text>
        </Paragraph>

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
            autoSize={{minRows: 4, maxRows: 8}}
            onChange={handleChangeBody}
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
  customerId?: string;
  title?: string;
  onSuccess: (data: any) => void;
};

export const NewIssueModalButton = ({
  customerId,
  title,
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
      <NewIssueModal
        visible={isModalOpen}
        header={title}
        customerId={customerId}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};

export default NewIssueModal;
