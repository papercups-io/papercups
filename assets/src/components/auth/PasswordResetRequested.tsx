import React from 'react';
import {Flex} from 'theme-ui';
import {Result} from '../common';

export const PasswordResetRequested = () => {
  return (
    <Flex my={5} sx={{justifyContent: 'center'}}>
      <Result
        status="success"
        title="Please check your email"
        subTitle="We'll send you a link to reset your password 😊"
      />
    </Flex>
  );
};

export default PasswordResetRequested;
