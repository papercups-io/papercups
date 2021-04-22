import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popconfirm} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {GITHUB_APP_NAME} from '../../config';
import {IntegrationType} from './support';

export const GithubAuthorizationButton = ({
  integration,
  onUpdate,
}: {
  integration: IntegrationType;
  onUpdate: () => void;
}) => {
  const {status, authorization_id: authorizationId} = integration;
  const isConnected = status === 'connected' && !!authorizationId;

  const handleDisconnect = async () => {
    if (!authorizationId) {
      return;
    }

    return API.deleteGithubAuthorization(authorizationId)
      .then(() => onUpdate())
      .catch((err) =>
        logger.error('Error deleting Github authorization!', err)
      );
  };

  return (
    <>
      {isConnected ? (
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
              onConfirm={handleDisconnect}
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
