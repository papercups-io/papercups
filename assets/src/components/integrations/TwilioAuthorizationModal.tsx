import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Divider,
  Input,
  Modal,
  Paragraph,
  Popconfirm,
  Text,
} from '../common';
import * as API from '../../api';
import {TwilioAuthorization} from '../../types';
import logger from '../../logger';
import {IntegrationType} from './support';

const TwilioAuthorizationModal = ({
  visible,
  authorizationId,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  authorizationId?: string | null;
  onSuccess: (authorization: TwilioAuthorization) => void;
  onCancel: () => void;
}) => {
  const [authorization, setAuthorization] = React.useState<TwilioAuthorization>(
    {}
  );
  const [isSaving, setSaving] = React.useState(false);
  const [error, setErrorMessage] = React.useState<string | null>(null);

  const handleSetAuthorization = async () => {
    setSaving(true);

    try {
      const params = authorizationId
        ? {...authorization, id: authorizationId}
        : authorization;
      const result = await API.createTwilioAuthorization(params);

      if (result.ok) {
        setErrorMessage(null);

        return onSuccess(result);
      } else {
        setErrorMessage(
          'Invalid Twilio authorization details. Please check the inputs above and try again.'
        );
      }
    } catch (err) {
      logger.error('Error creating Twilio authorization!', err);
    } finally {
      setSaving(false);
    }
  };

  const handleChangeAccountSid = (e: React.ChangeEvent<HTMLInputElement>) =>
    setAuthorization({...authorization, twilio_account_sid: e.target.value});

  const handleChangeAuthToken = (e: React.ChangeEvent<HTMLInputElement>) =>
    setAuthorization({...authorization, twilio_auth_token: e.target.value});

  const handleChangePhoneNumber = (e: React.ChangeEvent<HTMLInputElement>) =>
    setAuthorization({...authorization, from_phone_number: e.target.value});

  const handleCancel = () => {
    onCancel();
    setAuthorization({});
  };

  const {
    twilio_auth_token: authToken,
    twilio_account_sid: accountSid,
    from_phone_number: phoneNumber,
  } = authorization;

  return (
    <Modal
      title="Connect to Twilio"
      visible={visible}
      onOk={handleSetAuthorization}
      onCancel={handleCancel}
      footer={[
        <Button key="cancel" onClick={handleCancel}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleSetAuthorization}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Paragraph>
          <Text type="secondary">
            Please provide your Twilio API credentials to get started.
          </Text>
        </Paragraph>
        <Paragraph>
          <Text type="secondary">
            To get set up, please follow{' '}
            <a
              href="https://docs.papercups.io/reply-via-sms"
              target="_blank"
              rel="noopener noreferrer"
            >
              these instructions
            </a>
            .
          </Text>
        </Paragraph>

        <Divider />

        <Box mb={3}>
          <label htmlFor="twilio_account_sid">
            <Text strong>Twilio account SID</Text>
          </label>

          <Input
            id="twilio_account_sid"
            type="text"
            value={accountSid}
            autoFocus
            placeholder="AC1xxxxxa2b"
            onChange={handleChangeAccountSid}
          />
        </Box>

        <Box mb={3}>
          <label htmlFor="twilio_auth_token">
            <Text strong>Twilio auth token</Text>
          </label>

          <Input
            id="twilio_auth_token"
            type="text"
            value={authToken}
            placeholder="ab12cd34"
            onChange={handleChangeAuthToken}
          />
        </Box>

        <Box mb={3}>
          <label htmlFor="from_phone_number">
            <Text strong>Twilio phone number</Text>
          </label>

          <Input
            id="from_phone_number"
            type="text"
            value={phoneNumber}
            placeholder="+16501235555"
            onChange={handleChangePhoneNumber}
          />
        </Box>

        <Box>
          <Text type="danger">{error}</Text>
        </Box>
      </Box>
    </Modal>
  );
};

export const TwilioAuthorizationButton = ({
  integration,
  onUpdate,
}: {
  integration: IntegrationType;
  onUpdate: () => void;
}) => {
  const [isOpen, setOpen] = React.useState(false);

  const {status, authorization_id: authorizationId} = integration;
  const isConnected = status === 'connected' && !!authorizationId;

  const handleOpenModal = () => setOpen(true);
  const handleCloseModal = () => setOpen(false);
  const handleSuccess = () => {
    onUpdate();
    handleCloseModal();
  };

  const handleDisconnect = async () => {
    if (!authorizationId) {
      return;
    }

    return API.deleteTwilioAuthorization(authorizationId)
      .then(() => onUpdate())
      .catch((err) =>
        logger.error('Error deleting Twilio authorization!', err)
      );
  };

  return (
    <>
      {isConnected ? (
        <Flex mx={-1}>
          <Box mx={1}>
            <Button onClick={handleOpenModal}>Update</Button>
          </Box>
          <Box mx={1}>
            <Popconfirm
              title="Are you sure you want to disconnect from Twilio?"
              okText="Yes"
              cancelText="No"
              placement="topLeft"
              onConfirm={handleDisconnect}
            >
              <Button danger>Disconnect</Button>
            </Popconfirm>
          </Box>
        </Flex>
      ) : (
        <Button onClick={handleOpenModal}>Connect</Button>
      )}
      <TwilioAuthorizationModal
        visible={isOpen}
        authorizationId={authorizationId}
        onSuccess={handleSuccess}
        onCancel={handleCloseModal}
      />
    </>
  );
};

export default TwilioAuthorizationModal;
