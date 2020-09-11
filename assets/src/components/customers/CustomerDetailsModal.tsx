import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Button, Modal, Paragraph, Text} from '../common';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

export const CustomerDetailsContent = ({customer}: {customer: any}) => {
  const {
    email,
    name,
    browser,
    os,
    phone,
    external_id: externalId,
    created_at: createdAt,
    updated_at: lastUpdatedAt,
    current_url: lastSeenUrl,
    ip: lastIpAddress,
  } = customer;

  return (
    <Box>
      <Box mb={2}>
        <Box>
          <Text strong>Name</Text>
        </Box>

        <Paragraph>{name || 'Unknown'}</Paragraph>
      </Box>

      <Flex sx={{justifyContent: 'space-between'}}>
        <Box mb={2} sx={{flex: 1}}>
          <Box>
            <Text strong>Email</Text>
          </Box>

          <Paragraph>{email || 'Unknown'}</Paragraph>
        </Box>
        <Box mb={2} sx={{flex: 1}}>
          <Box>
            <Text strong>Phone</Text>
          </Box>

          <Paragraph>{phone || 'Unknown'}</Paragraph>
        </Box>
      </Flex>

      <Box mb={2}>
        <Box>
          <Text strong>ID</Text>
        </Box>

        <Paragraph>{externalId || 'Unknown'}</Paragraph>
      </Box>

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
          <a href="lastSeenUrl" target="_blank" rel="noopener noreferrer">
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
    </Box>
  );
};

type Props = {
  customer: any;
  isVisible?: boolean;
  onClose: () => void;
};

const CustomerDetailsModal = ({customer, isVisible, onClose}: Props) => {
  return (
    <Modal
      title="Customer details"
      visible={isVisible}
      onCancel={onClose}
      onOk={onClose}
      footer={<Button onClick={onClose}>Close</Button>}
    >
      <CustomerDetailsContent customer={customer} />
    </Modal>
  );
};

export default CustomerDetailsModal;
