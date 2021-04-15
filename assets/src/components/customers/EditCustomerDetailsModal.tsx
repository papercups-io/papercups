import React from 'react';
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
  onDelete: () => void;
  onUpdate: () => void;
};

type State = {
  email?: string;
  error?: string;
  isDeleting: boolean;
  isSaving: boolean;
  name?: string;
  phone?: string | number;
};

class EditCustomerDetailsModal extends React.Component<Props, State> {
  state: State = {
    email: this.props.customer.email,
    isDeleting: false,
    isSaving: false,
    name: this.props.customer.name,
    phone: this.props.customer.phone,
  };

  handleChangeName = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({name: e.target.value});
  };

  handleChangeEmail = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({email: e.target.value});
  };

  handleChangePhone = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({phone: e.target.value});
  };

  handleSave = async () => {
    this.setState({error: '', isSaving: true});

    const {customer, onUpdate} = this.props;
    const {name, email, phone} = this.state;

    try {
      await API.updateCustomer(customer.id, {
        name,
        email,
        phone,
      });
      onUpdate();
    } catch (err) {
      logger.error('Failed to update customer', err);
      const error =
        err.response?.body?.error?.message ||
        'Something went wrong. Please try again later.';

      this.setState({error, isSaving: false});
    }

    this.setState({isSaving: false});
  };

  handleDelete = async () => {
    this.setState({isDeleting: true});

    const {customer, onDelete} = this.props;
    const {id: customerId} = customer;
    const title = customer?.title ?? 'Customer';

    try {
      await API.deleteCustomer(customerId);
      notification.success({
        message: `${title} successfully deleted.`,
        duration: 10,
      });
      onDelete();
    } catch (err) {
      logger.error('Failed to delete customer', err);
      notification.error({
        message: `Failed to delete ${title}. Please try again later.`,
        duration: 10,
      });
    }

    this.setState({isDeleting: false});
  };

  render() {
    const {isVisible, onClose} = this.props;
    const {isSaving, isDeleting, name, email, phone, error} = this.state;

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
                onConfirm={this.handleDelete}
              >
                <Button danger loading={isDeleting}>
                  Delete
                </Button>
              </Popconfirm>
            </Box>
            <Button onClick={this.handleSave} loading={isSaving} type="primary">
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
              onChange={this.handleChangeName}
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
              onChange={this.handleChangeEmail}
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
              onChange={this.handleChangePhone}
            />
          </Box>

          {error && (
            <Box mt={2}>
              <Text type="danger">{error}</Text>
            </Box>
          )}
        </Box>
      </Modal>
    );
  }
}

export default EditCustomerDetailsModal;
