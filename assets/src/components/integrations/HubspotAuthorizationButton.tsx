import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popconfirm} from '../common';

// const HUBSPOT_CLIENT_ID = '01ec4478-4828-43b5-b505-38f517856add';
// const HUBSPOT_REDIRECT_URI = 'http://localhost:3000/integrations/hubspot';
// const HUBSPOT_OAUTH_URL = `https://app.hubspot.com/oauth/authorize?client_id=${HUBSPOT_CLIENT_ID}&redirect_uri=${HUBSPOT_REDIRECT_URI}&scope=contacts%20content`;
const HUBSPOT_OAUTH_URL =
  'https://app.hubspot.com/oauth/authorize?client_id=01ec4478-4828-43b5-b505-38f517856add&redirect_uri=http://localhost:3000/integrations/hubspot&scope=contacts%20content';

export const HubspotAuthorizationButton = ({
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
              href={HUBSPOT_OAUTH_URL}
              target="_blank"
              rel="noopener noreferrer"
            >
              <Button>Reconnect</Button>
            </a>
          </Box>
          <Box mx={1}>
            <Popconfirm
              title="Are you sure you want to disconnect from Hubspot?"
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
        <a href={HUBSPOT_OAUTH_URL} target="_blank" rel="noopener noreferrer">
          <Button>Connect</Button>
        </a>
      )}
    </>
  );
};

export default HubspotAuthorizationButton;
