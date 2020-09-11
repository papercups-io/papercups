import React from 'react';
import {Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Result} from '../common';

export const PasswordResetRequested = () => {
  return (
    <Flex my={5} sx={{justifyContent: 'center'}}>
      <Result
        status="success"
        title="Please check your email"
        subTitle={
          <Box>
            <Box>
              We'll send you a link to reset your password{' '}
              <span role="img" aria-label=":)">
                😊
              </span>
            </Box>
            <Box>
              If you don't see it in a few minutes, you may need to check your
              spam folder.
            </Box>
          </Box>
        }
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
