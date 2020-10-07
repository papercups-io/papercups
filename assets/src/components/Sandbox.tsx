import React from 'react';
import {Flex} from 'theme-ui';

export const Sandbox = () => {
  // Just using this page as a place to hack on UI components before they're ready
  return (
    <Flex p={2} sx={{flex: 1}}>
      UI Sandbox!
    </Flex>
  );
};

export default Sandbox;
