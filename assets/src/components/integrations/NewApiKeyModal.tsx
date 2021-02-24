import React from 'react';
import {Box} from 'theme-ui';
import {Button, Divider, Input, Modal, Paragraph, Text} from '../common';
import * as API from '../../api';
import {PersonalApiKey} from '../../types';
import logger from '../../logger';

const NewApiKeyModal = ({
  visible,
  onSuccess,
  onCancel,
}: {
  visible: boolean;
  onSuccess: (personalApiKey: PersonalApiKey) => void;
  onCancel: () => void;
}) => {
  const [name, setName] = React.useState('');
  const [isSaving, setSaving] = React.useState(false);

  const handleChangeName = (e: React.ChangeEvent<HTMLInputElement>) =>
    setName(e.target.value);

  const handleGenerateApiKey = async () => {
    setSaving(true);

    API.createPersonalApiKey(name)
      .then((personalApiKey) => {
        onSuccess(personalApiKey);
        setName('');
      })
      .catch((err) => logger.log('Error generating API key:', err))
      .finally(() => setSaving(false));
  };

  const handleCancelApiKey = () => {
    onCancel();
    setName('');
  };

  return (
    <Modal
      title="Generate new API key"
      visible={visible}
      onOk={handleGenerateApiKey}
      onCancel={handleCancelApiKey}
      footer={[
        <Button key="cancel" onClick={handleCancelApiKey}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleGenerateApiKey}
        >
          Generate API key
        </Button>,
      ]}
    >
      <Box>
        <Box>
          <label htmlFor="name">
            <Text strong>Description</Text>
          </label>

          <Input
            key={visible ? 'visible' : 'invisible'}
            id="name"
            size="large"
            type="text"
            value={name}
            autoFocus={visible}
            placeholder="Test API Key"
            onChange={handleChangeName}
          />
        </Box>

        <Divider />

        <Paragraph>
          <Text type="secondary">
            This will generate a new API key for your personal use. Please do
            not check this key into version control (e.g. GitHub) or share it
            with anybody outside of your organization.
          </Text>
        </Paragraph>
      </Box>
    </Modal>
  );
};

export default NewApiKeyModal;
