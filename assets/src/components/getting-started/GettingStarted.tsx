import React from 'react';
import {Box, Flex, Spinner} from 'theme-ui';

import * as API from '../../api';
import {SetupStatus} from '../../types';
import logger from '../../logger';
import {Divider, Title} from '../common';
import Steps from './Steps';

const GettingStarted = () => {
  const [setupStatus, setSetupStatus] = React.useState<Partial<SetupStatus>>(
    {}
  );
  const [loading, setLoading] = React.useState(true);

  React.useEffect(() => {
    (async () => {
      try {
        setSetupStatus(await API.getSetupStatus());
      } catch (error) {
        logger.error('Failed to get setup status:', error);
      }

      setLoading(false);
    })();
  }, []);

  return loading ? (
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
  ) : (
    <Box p={4} sx={{maxWidth: 1080}}>
      <Box mb={4}>
        <Title level={3}>Welcome to Papercups</Title>
      </Box>
      <Divider />
      <Steps setupStatus={setupStatus} />
    </Box>
  );
};

export default GettingStarted;
