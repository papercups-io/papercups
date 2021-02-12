import React from 'react';
import {Box} from 'theme-ui';
import {Button, Input, Modal, Text} from '../common';
import * as API from '../../api';
import logger from '../../logger';

const formatTagErrors = (err: any) => {
  try {
    const error = err?.response?.body?.error ?? {};
    const {errors = {}, message, status} = error;

    if (status === 422 && Object.keys(errors).length > 0) {
      const messages = Object.keys(errors)
        .map((field) => {
          const description = errors[field];

          if (description) {
            return `${field} ${description}`;
          } else {
            return `invalid ${field}`;
          }
        })
        .join(', ');

      return `Error: ${messages}.`;
    } else {
      return (
        message ||
        err?.message ||
        'Something went wrong. Please contact us or try again in a few minutes.'
      );
    }
  } catch {
    return (
      err?.response?.body?.error?.message ||
      err?.message ||
      'Something went wrong. Please contact us or try again in a few minutes.'
    );
  }
};

const NewTagModal = ({
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

  const handleCancelTag = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateTag = async () => {
    setIsSaving(true);

    return API.createTag({name, description})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating tag:', err);
        const errorMessage = formatTagErrors(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new tag"
      visible={visible}
      width={400}
      onOk={handleCreateTag}
      onCancel={handleCancelTag}
      footer={[
        <Button key="cancel" onClick={handleCancelTag}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateTag}
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
            onChange={handleChangeName}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="description">Description</label>
          <Input
            id="description"
            type="text"
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

export default NewTagModal;
