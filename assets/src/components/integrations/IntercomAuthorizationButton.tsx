import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popconfirm} from '../common';
import {getIntercomAuthUrl} from './support';

export const IntercomAuthorizationButton = ({
  isConnected,
  authorizationId,
  onDisconnect,
}: {
  isConnected?: boolean;
  authorizationId?: string | null;
  onDisconnect: (id: string) => void;
}) => {
  const url = getIntercomAuthUrl();

  return (
    <>
      {authorizationId && isConnected ? (
        <Flex mx={-1}>
          <Box mx={1}>
            <a href={url} target="_blank" rel="noopener noreferrer">
              <Button>Reconnect</Button>
            </a>
          </Box>
          <Box mx={1}>
            <Popconfirm
              title="Are you sure you want to disconnect from Intercom?"
              okText="Yes"
              cancelText="No"
              placement="topLeft"
              onConfirm={() => onDisconnect(authorizationId)}
            >
              <Button danger>Disconnect</Button>
            </Popconfirm>
          </Box>
        </Flex>
      ) : (
        <a href={url} target="_blank" rel="noopener noreferrer">
          <Button>Connect</Button>
        </a>
      )}
    </>
  );
};

export default IntercomAuthorizationButton;
