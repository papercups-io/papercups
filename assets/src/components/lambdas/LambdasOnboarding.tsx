import React from 'react';
import {Flex} from 'theme-ui';
import {Papercups} from '@papercups-io/chat-widget';

import * as API from '../../api';
import {formatServerError, sleep} from '../../utils';
import {Button, Result, Text} from '../common';
import logger from '../../logger';

const LambdasOnboarding = () => {
  const [isSending, setSending] = React.useState(false);
  const [isSuccess, setSuccess] = React.useState(false);
  const [error, setErrorMessage] = React.useState<string | null>(null);

  const handleRequestAccess = async () => {
    setSending(true);

    try {
      const {email, account_id: accountId} = await API.me();
      const result = await API.sendAdminNotification({
        subject: 'Requesting access for Papercups Functions',
        text: `${email} (${accountId}) would like to request access to the new Functions feature in Papercups.`,
      });
      logger.debug('Successfully requested access:', result);
      await sleep(1000);

      setSuccess(true);
    } catch (err) {
      logger.error('Failed to create new conversation:', err);
      const message = formatServerError(err);

      setErrorMessage(message);
    }

    setSending(false);
  };

  if (error) {
    return (
      <Flex my={5} sx={{justifyContent: 'center'}}>
        <Result
          status="error"
          title="Unable to request access"
          subTitle={<Text>{error}</Text>}
          extra={
            <Button type="primary" onClick={Papercups.toggle}>
              Contact us for help
            </Button>
          }
        />
      </Flex>
    );
  } else if (isSuccess) {
    return (
      <Flex my={5} sx={{justifyContent: 'center'}}>
        <Result
          status="success"
          title="Your request was sent!"
          subTitle={
            <Text>
              We'll get back to your shortly to schedule an onboarding.
            </Text>
          }
        />
      </Flex>
    );
  }

  return (
    <Flex my={5} sx={{justifyContent: 'center'}}>
      <Result
        status="info"
        title="This feature is currently in alpha"
        subTitle={
          <Text>
            In order to enable this feature for your account, request access
            below and we'll be happy to onboard you ASAP.
          </Text>
        }
        extra={
          <Button
            type="primary"
            loading={isSending}
            onClick={handleRequestAccess}
          >
            Request access
          </Button>
        }
      />
    </Flex>
  );
};

export default LambdasOnboarding;
