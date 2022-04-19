import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popconfirm} from '../common';
import {GITHUB_APP_NAME} from '../../config';

export const GithubAuthorizationButton = ({
  isConnected,
  authorizationId,
  onDisconnect,
}: {
  isConnected?: boolean;
  authorizationId?: string | null;
  onDisconnect: (id: string) => void;
}) => {
  return (
    <>
      {authorizationId && isConnected ? (
        <Flex mx={-1}>
          <Box mx={1}>
            <a
              href={`https://github.com/apps/${GITHUB_APP_NAME}/installations/new`}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Button>Reconnect</Button>
            </a>
          </Box>
          <Box mx={1}>
            <Popconfirm
              title="Are you sure you want to disconnect from Github?"
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
        <a
          href={`https://github.com/apps/${GITHUB_APP_NAME}/installations/new`}
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button>Connect</Button>
        </a>
      )}
    </>
  );
};

export default GithubAuthorizationButton;
