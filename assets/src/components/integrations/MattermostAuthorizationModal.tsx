import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Divider,
  Input,
  Modal,
  Paragraph,
  Popconfirm,
  Select,
  Text,
} from '../common';
import * as API from '../../api';
import {MattermostAuthorization, MattermostChannel} from '../../types';
import logger from '../../logger';
import {IntegrationType} from './support';

const MattermostAuthorizationModal = ({
  visible,
  authorizationId,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  authorizationId?: string | null;
  onSuccess: (authorization: MattermostAuthorization) => void;
  onCancel: () => void;
}) => {
  const [authorization, setAuthorization] = React.useState<
    MattermostAuthorization
  >({});
  const [channels, setMattermostChannels] = React.useState<
    Array<MattermostChannel>
  >([]);
  const [isSaving, setSaving] = React.useState(false);

  const handleRefreshChannels = async (query: MattermostAuthorization) => {
    if (!query.access_token || !query.mattermost_url) {
      return;
    }

    try {
      const channels = await API.fetchMattermostChannels(query);

      setMattermostChannels(channels);
    } catch (err) {
      logger.error('Error fetching Mattermost channels!', err);
    }
  };

  const handleSetAuthorization = async () => {
    setSaving(true);

    try {
      const params = authorizationId
        ? {...authorization, id: authorizationId}
        : authorization;
      const result = await API.createMattermostAuthorization(params);

      return onSuccess(result);
    } catch (err) {
      logger.error('Error creating Mattermost authorization!', err);
    } finally {
      setSaving(false);
    }
  };

  const handleChangeUrl = (e: React.ChangeEvent<HTMLInputElement>) => {
    const updated = {...authorization, mattermost_url: e.target.value};
    const {mattermost_url: url, access_token: token} = updated;

    if (url && token) {
      handleRefreshChannels(updated);
    }

    setAuthorization(updated);
  };

  const handleChangeBotToken = (e: React.ChangeEvent<HTMLInputElement>) => {
    const updated = {...authorization, access_token: e.target.value};
    const {mattermost_url: url, access_token: token} = updated;

    if (url && token) {
      handleRefreshChannels(updated);
    }

    setAuthorization(updated);
  };

  const handleChangeWebhookToken = (e: React.ChangeEvent<HTMLInputElement>) =>
    setAuthorization({...authorization, verification_token: e.target.value});

  const handleChangeMattermostChannel = (value: string, record: any) => {
    const {channel = {} as MattermostChannel} = record;
    const {name, team_id, team_name} = channel;

    setAuthorization({
      ...authorization,
      channel_id: value,
      channel_name: name,
      team_domain: team_name,
      team_id,
    });
  };

  const handleCancel = () => {
    onCancel();
    setAuthorization({});
  };

  const {
    mattermost_url: mattermostUrl,
    access_token: accessToken,
    verification_token: verificationToken,
    channel_id: channelId,
  } = authorization;

  return (
    <Modal
      title="Connect to Mattermost"
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
            At the moment, we only support integrations with{' '}
            <Text strong>self-hosted Mattermost</Text> instances. In order to
            get set up, please follow{' '}
            <a
              href="https://docs.papercups.io/reply-from-mattermost"
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
          <label htmlFor="mattermost_url">
            <Text strong>Mattermost URL</Text>
          </label>

          <Input
            id="mattermost_url"
            type="text"
            value={mattermostUrl}
            autoFocus
            placeholder="https://my-mattermost-app.herokuapp.com"
            onChange={handleChangeUrl}
          />
        </Box>

        <Box mb={3}>
          <label htmlFor="bot_access_token">
            <Text strong>Bot token</Text>
          </label>

          <Input
            id="bot_access_token"
            type="text"
            value={accessToken}
            placeholder="ab12cd34"
            onChange={handleChangeBotToken}
          />
        </Box>

        <Box mb={3}>
          <label htmlFor="mattermost_channel">
            <Text strong>Mattermost channel</Text>
          </label>

          <Select
            style={{width: '100%'}}
            placeholder="Select a channel..."
            showSearch
            allowClear
            disabled={!mattermostUrl || !accessToken}
            value={channelId || undefined}
            onChange={(value: string, record: any) => {
              handleChangeMattermostChannel(value, record);
            }}
            options={channels.map((channel: any) => {
              const {id, name} = channel;

              return {id, key: id, label: `#${name}`, value: id, channel};
            })}
            filterOption={(input: string, option: any) => {
              const {label = ''} = option;

              return label.toLowerCase().indexOf(input.toLowerCase()) !== -1;
            }}
          />
        </Box>

        <Box mb={3}>
          <label htmlFor="outgoing_webhook_token">
            <Text strong>Outgoing webhook token</Text>
          </label>

          <Input
            id="outgoing_webhook_token"
            type="text"
            value={verificationToken}
            placeholder="ef56gh78"
            onChange={handleChangeWebhookToken}
          />
        </Box>
      </Box>
    </Modal>
  );
};

export const MattermostAuthorizationButton = ({
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

    return API.deleteMattermostAuthorization(authorizationId)
      .then(() => onUpdate())
      .catch((err) =>
        logger.error('Error deleting Mattermost authorization!', err)
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
              title="Are you sure you want to disconnect from Mattermost?"
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
      <MattermostAuthorizationModal
        visible={isOpen}
        authorizationId={authorizationId}
        onSuccess={handleSuccess}
        onCancel={handleCloseModal}
      />
    </>
  );
};

export default MattermostAuthorizationModal;
