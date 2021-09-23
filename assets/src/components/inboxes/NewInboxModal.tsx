import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';

import {Button, Input, Modal, Text, TextArea} from '../common';
import * as API from '../../api';
import {Inbox} from '../../types';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const NewInboxModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (inbox: Inbox) => void;
  onCancel: () => void;
}) => {
  const [name, setName] = React.useState('');
  const [description, setDescription] = React.useState('');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  const handleChangeName = (e: any) => setName(e.target.value);
  const handleChangeDescription = (e: any) => setDescription(e.target.value);
  const resetInputFields = () => {
    setName('');
    setDescription('');
    setErrorMessage(null);
  };

  const handleCancelInbox = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateInbox = async () => {
    setIsSaving(true);

    return API.createInbox({name, description})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating inbox:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new inbox"
      visible={visible}
      width={400}
      onOk={handleCreateInbox}
      onCancel={handleCancelInbox}
      footer={[
        <Button key="cancel" onClick={handleCancelInbox}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateInbox}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="name">Name</label>
          <Input
            id="inbox_name"
            type="text"
            autoFocus
            value={name}
            onChange={handleChangeName}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="description">Description</label>
          <TextArea
            id="inbox_description"
            value={description}
            onChange={handleChangeDescription}
          />
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

export const NewInboxModalButton = ({
  onSuccess,
  ...props
}: {onSuccess: (inbox: Inbox) => void} & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = (inbox: Inbox) => {
    handleCloseModal();
    onSuccess(inbox);
  };

  return (
    <>
      <Button {...props} onClick={handleOpenModal} />
      <NewInboxModal
        visible={isModalOpen}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};

export default NewInboxModal;
