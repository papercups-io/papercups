import React from 'react';
import {Box} from 'theme-ui';
import {ButtonProps} from 'antd/lib/button';
import {Button, Input, Modal, Paragraph, Text} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const NewForwardingAddressModal = ({
  visible,
  inboxId,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  inboxId?: string | null;
  onSuccess: (params: any) => void;
  onCancel: () => void;
}) => {
  const [sourceEmailAddress, setSourceEmailAddress] = React.useState('');
  const [description, setDescription] = React.useState('');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  const handleChangeSourceEmailAddress = (e: any) =>
    setSourceEmailAddress(e.target.value);

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
      inbox_id: inboxId,
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
        <Box mb={4}>
          <Box mb={1}>
            <label htmlFor="source_email_address">
              <Text strong>
                Which email address will you be forwarding from?
              </Text>
            </label>
          </Box>
          <Input
            id="source_email_address"
            type="text"
            value={sourceEmailAddress}
            placeholder="support@company.co"
            autoFocus
            onChange={handleChangeSourceEmailAddress}
          />
        </Box>

        <Box>
          <Box mb={1}>
            <Text strong>How to set up email forwarding</Text>
          </Box>

          <Paragraph>
            <Text type="secondary">
              To set up automatic email forwarding in Gmail, follow{' '}
              <a
                href="https://support.google.com/mail/answer/10957?hl=en"
                target="_blank"
                rel="noopener noreferrer"
              >
                these instructions
              </a>
              .
            </Text>
          </Paragraph>
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
  inboxId,
  onSuccess,
  ...rest
}: {
  inboxId?: string | null;
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
        inboxId={inboxId}
        onSuccess={handleSuccess}
        onCancel={handleCloseModal}
      />
    </>
  );
};

export default NewForwardingAddressModal;
