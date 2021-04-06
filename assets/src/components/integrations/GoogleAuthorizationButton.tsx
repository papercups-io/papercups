import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popconfirm} from '../common';
import {getGoogleAuthUrl} from './support';
import Tooltip from 'antd/lib/tooltip';

export const GoogleAuthorizationButton = ({
  isConnected,
  authorizationId,
  onDisconnectGmail,
}: {
  isConnected: boolean;
  authorizationId: string | null;
  onDisconnectGmail: (id: string) => void;
}) => {
  if (isConnected && authorizationId) {
    return (
      <Flex mx={-1}>
        <Box mx={1}>
          <a href={getGoogleAuthUrl('gmail')}>
            <Button>Reconnect</Button>
          </a>
        </Box>
        <Box mx={1}>
          <Popconfirm
            title="Are you sure you want to disconnect from Gmail?"
            okText="Yes"
            cancelText="No"
            placement="topLeft"
            onConfirm={() => onDisconnectGmail(authorizationId)}
          >
            <Button danger>Disconnect</Button>
          </Popconfirm>
        </Box>
      </Flex>
    );
  }
  return (
    <Tooltip
      title={
        <Box>
          Our verification with the Google API is pending, but you can still
          link your Gmail account to opt into new features.
        </Box>
      }
    >
      <a href={getGoogleAuthUrl('gmail')}>
        <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
      </a>
    </Tooltip>
  );
};
