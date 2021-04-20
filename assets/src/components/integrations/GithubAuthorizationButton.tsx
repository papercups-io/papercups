import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button} from '../common';
import * as API from '../../api';
import logger from '../../logger';
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
              href="https://github.com/apps/papercups-dev/installations/new"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Button>Reconnect</Button>
            </a>
          </Box>
          <Box mx={1}>
            <Button danger onClick={handleDisconnect}>
              Disconnect
            </Button>
          </Box>
        </Flex>
      ) : (
        <a
          href="https://github.com/apps/papercups-dev/installations/new"
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
