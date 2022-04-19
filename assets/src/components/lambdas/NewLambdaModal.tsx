import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';

import {Button, Input, Modal, Text, TextArea} from '../common';
import * as API from '../../api';
import {Lambda} from '../../types';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const NewLambdaModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (lambda: Lambda) => void;
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

  const handleCancelLambda = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateLambda = async () => {
    setIsSaving(true);

    return API.createNewLambda({name, description})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating function:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new function"
      visible={visible}
      width={400}
      onOk={handleCreateLambda}
      onCancel={handleCancelLambda}
      footer={[
        <Button key="cancel" onClick={handleCancelLambda}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateLambda}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="name">Name</label>
          <Input
            id="lambda_name"
            type="text"
            value={name}
            onChange={handleChangeName}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="description">Description</label>
          <TextArea
            id="lambda_description"
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

export const NewLambdaModalButton = ({
  onSuccess,
  ...props
}: {onSuccess: (lambda: Lambda) => void} & ButtonProps) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = (lambda: Lambda) => {
    handleCloseModal();
    onSuccess(lambda);
  };

  return (
    <>
      <Button {...props} onClick={handleOpenModal} />
      <NewLambdaModal
        visible={isModalOpen}
        onCancel={handleCloseModal}
        onSuccess={handleSuccess}
      />
    </>
  );
};

export default NewLambdaModal;
