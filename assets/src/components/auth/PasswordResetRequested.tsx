import React from 'react';
import {Link} from 'react-router-dom';
import {Flex} from 'theme-ui';
import {Button, Result} from '../common';

export const PasswordResetRequested = () => {
  return (
    <Flex my={5} sx={{justifyContent: 'center'}}>
      <Result
        status="success"
        title="Please check your email"
        subTitle="We'll send you a link to reset your password 😊"
        extra={
          <Link to="/login">
            <Button>Back to login</Button>
          </Link>
        }
      />
    </Flex>
  );
};

export default PasswordResetRequested;
