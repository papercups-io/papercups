import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors} from './common';

export const Sandbox = () => {
  return (
    <Flex
      m={4}
      p={4}
      sx={{flex: 1, border: `1px solid ${colors.primary}`, borderRadius: 4}}
    >
      <Box>Sandbox for development</Box>
    </Flex>
  );
};

export default Sandbox;
