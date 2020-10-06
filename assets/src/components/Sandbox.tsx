import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Text} from './common';

export const Sandbox = () => {
  return (
    <Flex p={2} sx={{flex: 1}}>
      <Box
        sx={{
          width: 240,
          bg: 'rgb(245, 245, 245)',
          border: `1px solid rgba(0,0,0,.06)`,
          borderRadius: 4,
        }}
      >
        <Box px={2} py={3} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
          <Box px={2} mb={3}>
            <Text strong>Conversation details</Text>
          </Box>

          <Box px={2}>ID: 123</Box>
          <Box px={2}>Status: Open</Box>
        </Box>

        <Box px={2} py={3}>
          <Box px={2} mb={3}>
            <Text strong>Customer details</Text>
          </Box>

          <Box
            my={2}
            p={2}
            sx={{
              bg: colors.white,
              border: '1px solid rgba(0,0,0,.06)',
              borderRadius: 4,
            }}
          >
            <Box mb={2}>
              <Text strong>Anonymous User</Text>
            </Box>
            <Box>test@test.com</Box>
            <Box>+1 (650) 123-1234</Box>
            <Box>ID: 123</Box>
          </Box>

          <Box
            my={2}
            p={2}
            sx={{
              bg: colors.white,
              border: '1px solid rgba(0,0,0,.06)',
              borderRadius: 4,
            }}
          >
            <Box mb={2}>
              <Text strong>Last seen</Text>
            </Box>
            <Box>October 05, 2020</Box>
            <Box>http://localhost:3000/demo</Box>
          </Box>

          <Box
            my={2}
            p={2}
            sx={{
              bg: colors.white,
              border: '1px solid rgba(0,0,0,.06)',
              borderRadius: 4,
            }}
          >
            <Box mb={2}>
              <Text strong>First seen</Text>
            </Box>
            <Box>September 20, 2020</Box>
          </Box>

          <Box
            my={2}
            p={2}
            sx={{
              bg: colors.white,
              border: '1px solid rgba(0,0,0,.06)',
              borderRadius: 4,
            }}
          >
            <Box mb={2}>
              <Text strong>Device</Text>
            </Box>
            <Box> Mac OS X </Box>
            <Box>Chrome</Box>
            <Box>127.0.0.1</Box>
          </Box>

          <Box
            my={2}
            p={2}
            sx={{
              bg: colors.white,
              border: '1px solid rgba(0,0,0,.06)',
              borderRadius: 4,
            }}
          >
            <Box mb={2}>
              <Text strong>Tags</Text>
            </Box>
            <Box>Customer details section</Box>
          </Box>
        </Box>
      </Box>
    </Flex>
  );
};

export default Sandbox;
