import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popconfirm, Tooltip} from '../common';
import {getGoogleAuthUrl} from './support';

export const SupportGmailAuthorizationButton = ({
  isConnected,
  inboxId,
  authorizationId,
  onDisconnectGmail,
}: {
  isConnected?: boolean;
  inboxId?: string | null;
  authorizationId?: string | null;
  onDisconnectGmail: (id: string) => void;
}) => {
  if (isConnected && authorizationId) {
    return (
      <Flex mx={-1}>
        <Box mx={1}>
          <a
            href={getGoogleAuthUrl({
              client: 'gmail',
              type: 'support',
              inbox_id: inboxId,
            })}
          >
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
      <a
        href={getGoogleAuthUrl({
          client: 'gmail',
          type: 'support',
          inbox_id: inboxId,
        })}
      >
        <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
      </a>
    </Tooltip>
  );
};

export const PersonalGmailAuthorizationButton = ({
  isConnected,
  inboxId,
  authorizationId,
  onDisconnectGmail,
}: {
  isConnected?: boolean;
  inboxId?: string | null;
  authorizationId?: string | null;
  onDisconnectGmail: (id: string) => void;
}) => {
  if (isConnected && authorizationId) {
    return (
      <Flex mx={-1}>
        <Box mx={1}>
          <a
            href={getGoogleAuthUrl({
              client: 'gmail',
              type: 'personal',
              inbox_id: inboxId,
            })}
          >
            <Button>Reconnect with Gmail</Button>
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
            <Button danger>Disconnect from Gmail</Button>
          </Popconfirm>
        </Box>
      </Flex>
    );
  }

  return (
    <Tooltip
      placement="right"
      title={
        <Box>
          Our verification with the Google API is pending, but you can still
          link your Gmail account to opt into new features.
        </Box>
      }
    >
      <a
        href={getGoogleAuthUrl({
          client: 'gmail',
          type: 'personal',
          inbox_id: inboxId,
        })}
      >
        <Button type="primary">
          {isConnected ? 'Reconnect with Gmail' : 'Connect with Gmail'}
        </Button>
      </a>
    </Tooltip>
  );
};

export const GoogleSheetsAuthorizationButton = ({
  isConnected,
  authorizationId,
  onDisconnect,
}: {
  isConnected?: boolean;
  authorizationId?: string | null;
  onDisconnect: (id: string) => void;
}) => {
  if (isConnected && authorizationId) {
    return (
      <Flex mx={-1}>
        <Box mx={1}>
          <a href={getGoogleAuthUrl({client: 'sheets'})}>
            <Button>Reconnect</Button>
          </a>
        </Box>
        <Box mx={1}>
          <Popconfirm
            title="Are you sure you want to disconnect from Google Sheets?"
            okText="Yes"
            cancelText="No"
            placement="topLeft"
            onConfirm={() => onDisconnect(authorizationId)}
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
          link your Google Sheets account to opt into new features.
        </Box>
      }
    >
      <a href={getGoogleAuthUrl({client: 'sheets'})}>
        <Button>{isConnected ? 'Reconnect' : 'Connect'}</Button>
      </a>
    </Tooltip>
  );
};
