import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Button, Modal, Text, Input} from '../common';
import * as API from '../../api';
import {Customer} from '../../types';
import logger from '../../logger';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

type Props = {
  customer: Customer;
  isVisible: boolean;
  onClose: () => void;
  onUpdate: () => Promise<void>;
};

type State = {
  email?: string;
  error?: string;
  isSaving: boolean;
  name?: string;
  phone?: string | number;
};

class EditCustomerDetailsModal extends React.Component<Props, State> {
  state: State = {
    email: this.props.customer.email,
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
      await onUpdate();
    } catch (err) {
      logger.error('Failed to update customer', err);
      const error =
        err.response?.body?.error?.message ||
        'Something went wrong. Please try again later.';

      this.setState({error, isSaving: false});
    }

    this.setState({isSaving: false});
  };

  render() {
    const {isVisible, onClose} = this.props;
    const {isSaving, name, email, phone, error} = this.state;

    return (
      <Modal
        title="Edit customer"
        visible={isVisible}
        onCancel={onClose}
        onOk={onClose}
        footer={
          <Flex sx={{justifyContent: 'space-between'}}>
            <Button onClick={onClose} type="link">
              Cancel
            </Button>
            <Button
              onClick={this.handleSave}
              disabled={isSaving}
              type="primary"
            >
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
