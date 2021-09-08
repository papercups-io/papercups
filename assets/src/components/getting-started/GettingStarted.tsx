import React from 'react';
import {Box, Flex} from 'theme-ui';

import * as API from '../../api';
import type {OnboardingStatus} from '../../types';
import logger from '../../logger';
import {Container, Divider, Title} from '../common';
import Spinner from '../Spinner';
import Steps from './Steps';

const GettingStarted = () => {
  const [onboardingStatus, setOnboardingStatus] = React.useState<
    Partial<OnboardingStatus>
  >({});
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    (async () => {
      try {
        setOnboardingStatus(await API.getOnboardingStatus());
      } catch (error) {
        logger.error('Failed to get setup status:', error);
      }

      setLoading(false);
    })();
  }, []);

  if (loading) {
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
      <Steps onboardingStatus={onboardingStatus} />
    </Container>
  );
};

export default GettingStarted;
