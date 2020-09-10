import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Result} from '../common';

export const EmailVerification = () => {
  return (
    <Box my={5}>
      <Result
        status="success"
        title="Email verified!"
        subTitle="Thanks for verifying your email address 😊"
      />
    </Box>
  );
};

export default EmailVerification;
