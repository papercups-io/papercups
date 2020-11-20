import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {capitalize} from 'lodash';
import {Button, Modal, Paragraph, Text, Input} from '../common';
import * as API from '../../api';
import {Customer} from '../../types';
import logger from '../../logger';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

export const CustomerMetadataSection = ({
  metadata,
}: {
  metadata?: Record<string, string>;
}) => {
  return !metadata ? null : (
    <React.Fragment>
      <Box
        mb={2}
        py={2}
        sx={{borderTop: '1px solid #f0f0f0', borderBottom: '1px solid #f0f0f0'}}
      >
        <Box>
          <Text strong>Custom metadata</Text>
        </Box>
      </Box>

      <Flex sx={{justifyContent: 'space-between', flexWrap: 'wrap'}}>
        {Object.entries(metadata).map(([key, value]: any) => {
          const label = capitalize(key).split('_').join(' ');
          return (
            <Box mb={2} sx={{flex: '0 50%'}} key={key}>
              <Box>
                <Text strong>{label}</Text>
              </Box>

              <Paragraph>{value.toString()}</Paragraph>
            </Box>
          );
        })}
      </Flex>
    </React.Fragment>
  );
};

type Props = {
  customer: Customer;
  isVisible?: boolean;
  onClose: () => void;
  onUpdate: (data: any) => Promise<void>;
};

type State = {
  updates: any;
  isEditing: boolean;
  isSaving: boolean;
};

class CustomerDetailsModal extends React.Component<Props, State> {
  state: State = {
    updates: this.getInitialUpdates(),
    isEditing: false,
    isSaving: false,
  };

  getInitialUpdates() {
    const {customer} = this.props;
    const editableFieldsWhitelist: Array<keyof Customer> = [
      'name',
      'email',
      'phone',
    ];

    return editableFieldsWhitelist.reduce((acc, field) => {
      return {...acc, [field]: customer[field] || null};
    }, {});
  }

  handleStartEditing = () => {
    this.setState({isEditing: true});
  };

  handleCancelEdit = () => {
    this.setState({
      updates: this.getInitialUpdates(),
      isEditing: false,
    });
  };

  handleEditCustomer = (updates: any) => {
    this.setState({updates: {...this.state.updates, ...updates}});
  };

  handleChangeName = (e: any) => {
    this.handleEditCustomer({name: e.target.value});
  };

  handleChangeEmail = (e: any) => {
    this.handleEditCustomer({email: e.target.value});
  };

  handleChangePhone = (e: any) => {
    this.handleEditCustomer({phone: e.target.value});
  };

  handleSaveUpdates = async () => {
    this.setState({isSaving: true});

    const {customer, onUpdate} = this.props;
    const {updates} = this.state;
    const {id: customerId} = customer;

    try {
      const result = await API.updateCustomer(customerId, updates);

      await onUpdate(result);
    } catch (err) {
      logger.error('Failed to update customer', err);
    }

    this.handleCancelEdit();
    this.setState({isSaving: false});
  };

  onModalClose = () => {
    this.handleCancelEdit();
    this.props.onClose();
  };

  render() {
    const {customer, isVisible} = this.props;
    const {isEditing, isSaving, updates} = this.state;
    const {
      browser,
      os,
      email,
      name,
      phone,
      external_id: externalId,
      created_at: createdAt,
      updated_at: lastUpdatedAt,
      current_url: lastSeenUrl,
      ip: lastIpAddress,
      metadata,
      time_zone,
    } = customer;

    return (
      <Modal
        title="Customer details"
        visible={isVisible}
        onCancel={this.onModalClose}
        onOk={this.onModalClose}
        footer={
          isEditing ? (
            <Flex sx={{justifyContent: 'space-between'}}>
              <Button onClick={this.onModalClose}>Close</Button>
              <Flex>
                <Button onClick={this.handleCancelEdit}>Cancel</Button>
                <Button
                  loading={isSaving}
                  type="primary"
                  onClick={this.handleSaveUpdates}
                >
                  Save
                </Button>
              </Flex>
            </Flex>
          ) : (
            <Flex sx={{justifyContent: 'space-between'}}>
              <Button onClick={this.onModalClose}>Close</Button>
              <Button type="primary" onClick={this.handleStartEditing}>
                Edit
              </Button>
            </Flex>
          )
        }
      >
        <Box>
          <Box mb={2}>
            <Box>
              <Text strong>Name</Text>
            </Box>
            {!isEditing ? (
              <Paragraph>{name || 'Unknown'}</Paragraph>
            ) : (
              <Box pr={2} mb={12}>
                <Input
                  style={{marginBottom: -8}}
                  id="name"
                  type="text"
                  size="small"
                  value={updates.name}
                  onChange={this.handleChangeName}
                />
              </Box>
            )}
          </Box>

          <Flex sx={{justifyContent: 'space-between'}}>
            <Box mb={2} sx={{flex: 1}}>
              <Box>
                <Text strong>Email</Text>
              </Box>
              {!isEditing ? (
                <Paragraph>{email || 'Unknown'}</Paragraph>
              ) : (
                <Box pr={2} mb={12}>
                  <Input
                    id="email"
                    type="text"
                    size="small"
                    value={updates.email}
                    onChange={this.handleChangeEmail}
                  />
                </Box>
              )}
            </Box>
            <Box mb={2} sx={{flex: 1}}>
              <Box>
                <Text strong>Phone</Text>
              </Box>
              {!isEditing ? (
                <Paragraph>{phone || 'Unknown'}</Paragraph>
              ) : (
                <Box pr={2} mb={12}>
                  <Input
                    id="phone"
                    type="text"
                    size="small"
                    value={updates.phone}
                    onChange={this.handleChangePhone}
                  />
                </Box>
              )}
            </Box>
          </Flex>

          <Flex>
            <Box mb={2} sx={{flex: 1}}>
              <Box>
                <Text strong>ID</Text>
              </Box>

              <Paragraph>{externalId || 'Unknown'}</Paragraph>
            </Box>
            <Box mb={2} sx={{flex: 1}}>
              <Box>
                <Text strong>Time zone</Text>
              </Box>

              <Paragraph>{time_zone || 'Unknown'}</Paragraph>
            </Box>
          </Flex>
          <Box mb={2}>
            <Box>
              <Text strong>Device information</Text>
            </Box>

            <Paragraph>
              {[lastIpAddress, os, browser].join(' · ') || 'N/A'}
            </Paragraph>
          </Box>

          <Box mb={2}>
            <Box>
              <Text strong>Last visited URL</Text>
            </Box>

            {lastSeenUrl ? (
              <a href={lastSeenUrl} target="_blank" rel="noopener noreferrer">
                {lastSeenUrl}
              </a>
            ) : (
              <Paragraph>N/A</Paragraph>
            )}
          </Box>

          <Flex sx={{justifyContent: 'space-between'}}>
            <Box mb={2} sx={{flex: 1}}>
              <Box>
                <Text strong>First seen</Text>
              </Box>

              <Paragraph>
                {createdAt
                  ? dayjs.utc(createdAt).format('MMMM DD, YYYY')
                  : 'N/A'}
              </Paragraph>
            </Box>

            <Box mb={2} sx={{flex: 1}}>
              <Box>
                <Text strong>Last seen</Text>
              </Box>

              <Paragraph>
                {lastUpdatedAt
                  ? dayjs.utc(lastUpdatedAt).format('MMMM DD, YYYY')
                  : 'N/A'}
              </Paragraph>
            </Box>
          </Flex>

          <CustomerMetadataSection metadata={metadata} />
        </Box>
      </Modal>
    );
  }
}

export default CustomerDetailsModal;
