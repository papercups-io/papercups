import React, {useState} from 'react';
import {useHistory} from 'react-router';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {
  Button,
  colors,
  Input,
  Modal,
  notification,
  Paragraph,
  Popconfirm,
  Text,
} from '../common';
import * as API from '../../api';
import {Customer} from '../../types';
import logger from '../../logger';
import {WarningTwoTone} from '../icons';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

type Props = {
  customer: Customer;
  isVisible: boolean;
  onClose: () => void;
  onUpdate: () => void;
};

const EditCustomerDetailsModal = ({
  customer,
  isVisible,
  onClose,
  onUpdate,
}: Props) => {
  const history = useHistory();
  const [email, setEmail] = useState(customer.email ?? '');
  const [name, setName] = useState(customer.name ?? '');
  const [phone, setPhone] = useState(customer.phone ?? '');
  const [error, setError] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async () => {
    setError('');
    setIsSaving(true);

    try {
      await API.updateCustomer(customer.id, {
        name,
        email,
        phone,
      });
      notification.success({
        message: `Customer successfully updated`,
        duration: 10,
      });
      onUpdate();
    } catch (err) {
      logger.error('Failed to update customer', err);
      const error =
        err.response?.body?.error?.message ||
        'Failed to update customer. Please try again later.';

      setError(error);
    }

    setIsSaving(false);
  };

  const handleDelete = async () => {
    setError('');
    setIsDeleting(true);

    const {id: customerId} = customer;
    const title = customer?.title ?? 'Customer';

    try {
      await API.deleteCustomer(customerId);
      notification.success({
        message: `${title} successfully deleted.`,
        duration: 10,
      });
      history.push('/customers');
    } catch (err) {
      logger.error('Failed to delete customer', err);
      const error =
        err.response?.body?.error?.message ||
        'Failed to delete customer. Please try again later.';

      setError(error);
    }

    setIsDeleting(false);
  };

  return (
    <Modal
      title="Edit customer"
      visible={isVisible}
      onCancel={onClose}
      onOk={onClose}
      footer={
        <Flex sx={{justifyContent: 'space-between'}}>
          <Box>
            <Button onClick={onClose} type="text">
              Cancel
            </Button>
            <Popconfirm
              title={
                <Box sx={{maxWidth: 320}}>
                  <Paragraph>
                    Are you sure you want to delete this customer and all of
                    their data?
                  </Paragraph>
                  <Paragraph>
                    <Text strong>Warning:</Text> this cannot be undone.
                  </Paragraph>
                </Box>
              }
              icon={<WarningTwoTone twoToneColor={colors.red} />}
              okText="Delete"
              okType="danger"
              cancelText="Cancel"
              cancelButtonProps={{type: 'text'}}
              placement="bottomLeft"
              onConfirm={handleDelete}
            >
              <Button danger loading={isDeleting}>
                Delete
              </Button>
            </Popconfirm>
          </Box>
          <Button onClick={handleSave} loading={isSaving} type="primary">
            Save
          </Button>
        </Flex>
      }
    >
      <Box mb={2} sx={{flex: 1}}>
        <Box>
          <Text strong>Name</Text>
        </Box>
        <Box pr={2} mb={12}>
          <Input
            style={{marginBottom: -8}}
            id="name"
            type="text"
            value={name}
            onChange={(event) => setName(event.currentTarget.value)}
          />
        </Box>
      </Box>
      <Box mb={2} sx={{flex: 1}}>
        <Box>
          <Text strong>Email</Text>
        </Box>
        <Box pr={2} mb={12}>
          <Input
            id="email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.currentTarget.value)}
          />
        </Box>
      </Box>
      <Box mb={2} sx={{flex: 1}}>
        <Box>
          <Text strong>Phone</Text>
        </Box>
        <Box pr={2} mb={12}>
          <Input
            id="phone"
            type="text"
            value={phone}
            onChange={(event) => setPhone(event.currentTarget.value)}
          />
        </Box>
      </Box>
      {error && (
        <Box mt={3}>
          <Text type="danger" strong>
            {error}
          </Text>
        </Box>
      )}
    </Modal>
  );
};

export default EditCustomerDetailsModal;
