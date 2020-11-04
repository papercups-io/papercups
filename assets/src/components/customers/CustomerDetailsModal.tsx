import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {capitalize} from 'lodash';
import {Button, Modal, Paragraph, Text, Input} from '../common';
import * as API from '../../api';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

export const CustomerMetadataSection = ({
  metadata,
}: {
  metadata: Record<string, string>;
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

export const CustomerDetailsContent = ({customer}: {customer: any}) => {
  const {
    browser,
    os,
    external_id: externalId,
    created_at: createdAt,
    updated_at: lastUpdatedAt,
    current_url: lastSeenUrl,
    ip: lastIpAddress,
    metadata,
    time_zone,
  } = customer;

  return (
    <Box>
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
            {createdAt ? dayjs.utc(createdAt).format('MMMM DD, YYYY') : 'N/A'}
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
  );
};

type Props = {
  customer: any;
  isVisible?: boolean;
  onClose: () => void;
  onUpdate: (updatedData: any) => void;
};

type State = {
  email: string;
  name: string;
  phone: string;
  isEditing: boolean;
};

class CustomerDetailsModal extends React.Component<Props, State> {
  state: State = {
    email: this.props.customer.email,
    name: this.props.customer.name,
    phone: this.props.customer.phone,
    isEditing: false,
  };

  onEdit: any = () => {
    this.setState({isEditing: true});
  };

  onCancelEdit: any = () => {
    this.setState({
      email: this.props.customer.email,
      name: this.props.customer.name,
      phone: this.props.customer.phone,
      isEditing: false,
    });
  };

  handleChangeName: any = (e: any) => {
    this.setState({name: e.target.value});
  };

  handleChangeEmail = (e: any) => {
    this.setState({email: e.target.value});
  };

  handleChangePhone = (e: any) => {
    this.setState({phone: e.target.value});
  };

  onSave: any = () => {
    const {name, email, phone} = this.state;
    const id = this.props.customer.key;
    this.props.onUpdate({name, email, phone, id});

    return API.updateCustomer(id, {
      name: name,
      email: email,
      phone: phone,
    }).then(() => this.setState({isEditing: false}));
  };

  onModalClose: any = () => {
    this.setState({
      email: this.props.customer.email,
      name: this.props.customer.name,
      phone: this.props.customer.phone,
      isEditing: false,
    });
    this.props.onClose();
  };

  render() {
    const {name, email, phone, isEditing} = this.state;
    return (
      <Modal
        title="Customer details"
        visible={this.props.isVisible}
        onCancel={this.onModalClose}
        onOk={this.onModalClose}
        footer={
          !this.state.isEditing
            ? [
                <Button onClick={this.onModalClose}>Close</Button>,
                <Button onClick={this.onEdit}>Edit</Button>,
              ]
            : [
                <Button onClick={this.onCancelEdit}>Cancel</Button>,
                <Button onClick={this.onSave}>Save</Button>,
              ]
        }
      >
        <Box mb={2}>
          <Box>
            <Text strong>Name</Text>
          </Box>
          {!isEditing ? (
            <Paragraph>{name || 'Unknown'}</Paragraph>
          ) : (
            <Input
              id="name"
              type="text"
              value={name}
              onChange={this.handleChangeName}
              placeholder="Full Name"
            />
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
              <Input
                id="email"
                type="text"
                value={email}
                onChange={this.handleChangeEmail}
                placeholder="E-Mail Address"
              />
            )}
          </Box>
          <Box mb={2} sx={{flex: 1}}>
            <Box>
              <Text strong>Phone</Text>
            </Box>
            {!isEditing ? (
              <Paragraph>{phone || 'Unknown'}</Paragraph>
            ) : (
              <Input
                id="phone"
                type="text"
                value={phone}
                onChange={this.handleChangePhone}
                placeholder="Phone No."
              />
            )}
          </Box>
        </Flex>

        <CustomerDetailsContent customer={this.props.customer} />
      </Modal>
    );
  }
}

export default CustomerDetailsModal;
