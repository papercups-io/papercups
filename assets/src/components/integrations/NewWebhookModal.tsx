import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Divider, Input, Modal, Paragraph, Text} from '../common';
import * as API from '../../api';
import {sleep} from '../../utils';
import logger from '../../logger';
import {WebhookEventSubscription} from './support';

// TODO: clean up a bit
const NewWebhookModal = ({
  webhook,
  visible,
  onSuccess,
  onCancel,
}: {
  webhook?: WebhookEventSubscription | null;
  visible: boolean;
  onSuccess: (webhook: WebhookEventSubscription) => void;
  onCancel: () => void;
}) => {
  const defaultWebhookUrl = webhook?.webhook_url ?? '';
  const [url, setWebhookUrl] = React.useState(defaultWebhookUrl);
  const [isVerifying, setIsVerifying] = React.useState(false);
  const [isVerified, setIsVerified] = React.useState(false);
  const [isSaving, setIsSaving] = React.useState(false);

  // TODO: figure out a better way to handle this
  React.useEffect(() => {
    const url = webhook?.webhook_url ?? '';

    setWebhookUrl(url);
  }, [webhook]);

  const handleChangeUrl = (e: any) => setWebhookUrl(e.target.value);

  const handleVerifyUrl = async () => {
    logger.debug('Verifying:', url);
    setIsVerifying(true);

    const {verified} = await API.verifyWebhookUrl(url);
    logger.debug('Verified?', verified);
    await sleep(1000);

    setIsVerifying(false);
    setIsVerified(verified);
  };

  const handleCancelWebhook = () => {
    onCancel();
    setWebhookUrl('');
    setIsVerified(false);
  };

  const handleSaveWebhook = async () => {
    logger.debug('Saving:', url);
    setIsSaving(true);
    const existingWebhookId = webhook && webhook.id;
    const params = {webhook_url: url};
    const result = existingWebhookId
      ? await API.updateEventSubscription(existingWebhookId, params)
      : await API.createEventSubscription(params);

    setIsSaving(false);
    onSuccess(result);
    setWebhookUrl('');
    setIsVerified(false);
  };

  return (
    <Modal
      title="Add webhook URL"
      visible={visible}
      onOk={handleSaveWebhook}
      onCancel={handleCancelWebhook}
      footer={[
        <Button key="cancel" onClick={handleCancelWebhook}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          loading={isSaving}
          onClick={handleSaveWebhook}
        >
          Save
        </Button>,
      ]}
    >
      <Box>
        <Paragraph>
          <Text>
            You can subscribe to be notified of events in Papercups (for
            example, when a new message is created) at a URL of your choice.
          </Text>
        </Paragraph>

        <Box>
          <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
            <label htmlFor="webhook_url">
              <Text strong>Webhook URL</Text>
            </label>

            {isVerifying ? (
              <Text type="secondary">Verifying...</Text>
            ) : isVerified ? (
              <Text>Verified!</Text>
            ) : null}
          </Flex>
          <Input
            id="webhook_url"
            size="large"
            type="text"
            value={url}
            placeholder="https://myawesomeapp.com/api/webhook"
            onChange={handleChangeUrl}
            onBlur={handleVerifyUrl}
          />
        </Box>

        <Divider />

        <Paragraph>
          <Text type="secondary">
            We'll send HTTP POST requests to this URL when events occur. As soon
            as you enter a URL, we'll send a request with a{' '}
            <Text code>payload</Text> parameter, and your endpoint must respond
            with the value.
          </Text>
        </Paragraph>

        <Paragraph>
          <Text type="secondary">
            Note that for development URLs using <Text code>localhost</Text>,
            you may need to use a tool like{' '}
            <a
              href="https://ngrok.com/"
              target="_blank"
              rel="noopener noreferrer"
            >
              ngrok
            </a>{' '}
            to test your URL.
          </Text>
        </Paragraph>
      </Box>
    </Modal>
  );
};

export default NewWebhookModal;
