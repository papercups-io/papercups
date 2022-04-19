import React from 'react';
import {Box, Flex} from 'theme-ui';

import * as API from '../../api';
import {Inbox, OnboardingStatus} from '../../types';
import logger from '../../logger';
import {Container, Divider, Title} from '../common';
import Spinner from '../Spinner';
import Steps from './Steps';

const GettingStarted = () => {
  const [
    onboardingStatus,
    setOnboardingStatus,
  ] = React.useState<OnboardingStatus | null>(null);
  const [inbox, setDefaultInbox] = React.useState<Inbox | null>(null);
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    (async () => {
      try {
        const status = await API.getOnboardingStatus();
        const inboxes = await API.fetchInboxes();
        const [first] = inboxes;
        const primary = inboxes.find((inbox) => inbox.is_primary);

        setOnboardingStatus(status);
        setDefaultInbox(primary || first);
      } catch (error) {
        logger.error('Failed to get onboarding status:', error);
      }

      setLoading(false);
    })();
  }, []);

  if (loading || !onboardingStatus || !inbox) {
    return (
      <Flex
        sx={{
          flex: 1,
          justifyContent: 'center',
          alignItems: 'center',
          height: '100%',
        }}
      >
        <Spinner size={40} />
      </Flex>
    );
  }

  return (
    <Container sx={{maxWidth: 800}}>
      <Box mb={4} px={3}>
        <Title level={3}>Get started with Papercups</Title>
      </Box>
      <Divider />
      <Steps onboardingStatus={onboardingStatus} inbox={inbox} />
    </Container>
  );
};

export default GettingStarted;
