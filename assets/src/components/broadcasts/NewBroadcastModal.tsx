import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';

import {Button, Input, Modal, Text, TextArea} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {Broadcast} from '../../types';
import {formatServerError} from '../../utils';

const NewBroadcastModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (params: any) => void;
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

  const handleCancelBroadcast = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateBroadcast = async () => {
    setIsSaving(true);

    return API.createNewBroadcast({name, description})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating broadcast:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new broadcast"
      visible={visible}
      width={400}
      onOk={handleCreateBroadcast}
      onCancel={handleCancelBroadcast}
      footer={[
        <Button key="cancel" onClick={handleCancelBroadcast}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateBroadcast}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="name">Name</label>
          <Input
            id="name"
            type="text"
            autoFocus
            value={name}
            onChange={handleChangeName}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="description">Description</label>
          <TextArea
            id="description"
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

export const NewBroadcastModalButton = ({
  onSuccess,
  ...props
}: {onSuccess: (broadcast: Broadcast) => void} & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = (broadcast: Broadcast) => {
    handleCloseModal();
    onSuccess(broadcast);
  };

  return (
    <>
      <Button {...props} onClick={handleOpenModal} />
      <NewBroadcastModal
        visible={isModalOpen}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};

export default NewBroadcastModal;
