import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';

import {Button, Input, Modal, Text, TextArea} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {MessageTemplate} from '../../types';
import {formatServerError} from '../../utils';

const NewMessageTemplateModal = ({
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

  const handleCancelMessageTemplate = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateMessageTemplate = async () => {
    setIsSaving(true);

    return API.createMessageTemplate({name, description})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating template:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new template"
      visible={visible}
      width={400}
      onOk={handleCreateMessageTemplate}
      onCancel={handleCancelMessageTemplate}
      footer={[
        <Button key="cancel" onClick={handleCancelMessageTemplate}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateMessageTemplate}
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

export const NewMessageTemplateModalButton = ({
  onSuccess,
  ...props
}: {onSuccess: (template: MessageTemplate) => void} & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = (template: MessageTemplate) => {
    handleCloseModal();
    onSuccess(template);
  };

  return (
    <>
      <Button {...props} onClick={handleOpenModal} />
      <NewMessageTemplateModal
        visible={isModalOpen}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};

export default NewMessageTemplateModal;
