import React from 'react';
import {Box} from 'theme-ui';
import {Button, Input, Modal, Text} from '../common';
import {PlusOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';
import {formatServerError} from '../../utils';

const NewCustomerModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (params: any) => void;
  onCancel: () => void;
}) => {
  const [accountId, setAccountId] = React.useState('');
  const [email, setEmailAddress] = React.useState('');
  const [name, setName] = React.useState('');
  const [phone, setPhoneNumber] = React.useState('');
  const [error, setErrorMessage] = React.useState<string | null>(null);
  const [isSaving, setIsSaving] = React.useState(false);

  React.useEffect(() => {
    API.fetchAccountInfo()
      .then(({id: accountId}) => setAccountId(accountId))
      .catch((err) => logger.error('Failed to fetch account:', err));
  }, []);

  const handleChangeEmail = (e: React.ChangeEvent<HTMLInputElement>) =>
    setEmailAddress(e.target.value);
  const handleChangeName = (e: React.ChangeEvent<HTMLInputElement>) =>
    setName(e.target.value);
  const handleChangePhone = (e: React.ChangeEvent<HTMLInputElement>) =>
    setPhoneNumber(e.target.value);

  const resetInputFields = () => {
    setName('');
    setEmailAddress('');
    setPhoneNumber('');
    setErrorMessage(null);
  };

  const handleCancelCustomer = () => {
    onCancel();
    resetInputFields();
  };

  const handleCreateCustomer = async () => {
    setIsSaving(true);

    return API.createNewCustomer(accountId, {name, email, phone})
      .then((result) => {
        onSuccess(result);
        resetInputFields();
      })
      .catch((err) => {
        logger.error('Error creating customer:', err);
        const errorMessage = formatServerError(err);
        setErrorMessage(errorMessage);
      })
      .finally(() => setIsSaving(false));
  };

  return (
    <Modal
      title="Create new customer"
      visible={visible}
      width={400}
      onOk={handleCreateCustomer}
      onCancel={handleCancelCustomer}
      footer={[
        <Button key="cancel" onClick={handleCancelCustomer}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateCustomer}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Box mb={3}>
          <label htmlFor="email">Email</label>
          <Input
            id="email"
            type="email"
            value={email}
            onChange={handleChangeEmail}
          />
        </Box>
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
          <label htmlFor="phone">Phone</label>
          <Input
            id="phone"
            type="text"
            placeholder="Optional"
            value={phone}
            onChange={handleChangePhone}
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

export const NewCustomerButton = ({
  onSuccess,
}: {
  onSuccess: (data?: any) => void;
}) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenModal = () => setModalOpen(true);
  const handleCloseModal = () => setModalOpen(false);
  const handleSuccess = () => {
    onSuccess();
    handleCloseModal();
  };

  return (
    <>
      <Button type="primary" icon={<PlusOutlined />} onClick={handleOpenModal}>
        New customer
      </Button>
      <NewCustomerModal
        visible={isModalOpen}
        onSuccess={handleSuccess}
        onCancel={handleCloseModal}
      />
    </>
  );
};

export default NewCustomerModal;
