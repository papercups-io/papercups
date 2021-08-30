import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';
import {Button, Input, Modal, Text, TextArea} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const NewForwardingAddressModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (params: any) => void;
  onCancel: () => void;
}) => {
  const [sourceEmailAddress, setSourceEmailAddress] = React.useState('');
  const [description, setDescription] = React.useState('');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  const handleChangeSourceEmailAddress = (e: any) =>
    setSourceEmailAddress(e.target.value);
  const handleChangeDescription = (e: any) => setDescription(e.target.value);
  const resetInputFields = () => {
    setSourceEmailAddress('');
    setDescription('');
    setErrorMessage(null);
  };

  const handleCancelForwardingAddress = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateForwardingAddress = async () => {
    setIsSaving(true);

    return API.createForwardingAddress({
      description,
      source_email_address: sourceEmailAddress,
    })
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating forwarding address:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new forwarding address"
      visible={visible}
      width={400}
      onOk={handleCreateForwardingAddress}
      onCancel={handleCancelForwardingAddress}
      footer={[
        <Button key="cancel" onClick={handleCancelForwardingAddress}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateForwardingAddress}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="source_email_address">
            Which email address will you be forwarding from?
          </label>
          <Input
            id="source_email_address"
            type="text"
            value={sourceEmailAddress}
            placeholder="support@company.co"
            autoFocus
            onChange={handleChangeSourceEmailAddress}
          />
        </Box>
        <Box mb={3}>
          <label htmlFor="description">Description</label>
          <TextArea
            id="description"
            value={description}
            placeholder="Optional"
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

export const NewForwardingAddressModalButton = ({
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

      <NewForwardingAddressModal
        visible={isModalOpen}
        onSuccess={handleSuccess}
        onCancel={handleCloseModal}
      />
    </>
  );
};

export default NewForwardingAddressModal;
