import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';
import {Button, Input, Modal, Text, TextArea} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const NewCannedResponseModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (params: any) => void;
  onCancel: () => void;
}) => {
  const [name, setName] = React.useState('');
  const [content, setContent] = React.useState('');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  const handleChangeName = (e: any) => setName(e.target.value);
  const handleChangeContent = (e: any) => setContent(e.target.value);
  const resetInputFields = () => {
    setName('');
    setContent('');
    setErrorMessage(null);
  };

  const handleCancelCannedResponse = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateCannedResponse = async () => {
    setIsSaving(true);

    return API.createCannedResponse({name: name.replace('/', ''), content})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating saved reply:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new saved reply"
      visible={visible}
      width={400}
      onOk={handleCreateCannedResponse}
      onCancel={handleCancelCannedResponse}
      footer={[
        <Button key="cancel" onClick={handleCancelCannedResponse}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateCannedResponse}
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
            value={name}
            placeholder="demo"
            autoFocus
            onChange={handleChangeName}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="content">Content</label>
          <TextArea
            id="content"
            value={content}
            placeholder="Check out our demo at https://example.com/demo"
            onChange={handleChangeContent}
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

export const NewCannedResponseModalButton = ({
  onSuccess,
  ...rest
}: {
  onSuccess: (data?: any) => void;
} & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = () => {
    onSuccess();
    handleCloseModal();
  };

  return (
    <>
      <Button
        type="primary"
        icon={<PlusOutlined />}
        onClick={handleOpenModal}
        {...rest}
      />

      <NewCannedResponseModal
        visible={isModalOpen}
        onSuccess={handleSuccess}
        onCancel={handleCloseModal}
      />
    </>
  );
};

export default NewCannedResponseModal;
