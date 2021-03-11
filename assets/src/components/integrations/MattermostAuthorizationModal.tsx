import React from 'react';
import {Box} from 'theme-ui';
import {Button, Input, Modal, Select, Text} from '../common';
import * as API from '../../api';
import {MattermostAuthorization, MattermostChannel} from '../../types';
import logger from '../../logger';

const MattermostAuthorizationModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
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

  const handleCreateAuthorization = async () => {
    setSaving(true);

    try {
      const result = await API.createMattermostAuthorization(authorization);

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
      onOk={handleCreateAuthorization}
      onCancel={handleCancel}
      footer={[
        <Button key="cancel" onClick={handleCancel}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleCreateAuthorization}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
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
            autoFocus
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
            autoFocus
            placeholder="ef56gh78"
            onChange={handleChangeWebhookToken}
          />
        </Box>
      </Box>
    </Modal>
  );
};

export default MattermostAuthorizationModal;
