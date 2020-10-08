import React from 'react';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {colors, Tag, Text, Tooltip} from '../common';
import {
  CalendarOutlined,
  GlobalOutlined,
  MailOutlined,
  PhoneOutlined,
  UserOutlined,
} from '../icons';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

const DetailsSectionCard = ({children}: {children: any}) => {
  return (
    <Box
      my={2}
      p={2}
      sx={{
        bg: colors.white,
        border: '1px solid rgba(0,0,0,.06)',
        borderRadius: 4,
      }}
    >
      {children}
    </Box>
  );
};

type Props = {
  customer: any;
  conversation: any;
};

const ConversationDetailsSidebar = ({customer, conversation}: Props) => {
  const {id: conversationId, status} = conversation;
  const {
    email,
    name,
    browser,
    os,
    phone,
    pathname,
    id: customerId,
    external_id: externalId,
    created_at: createdAt,
    updated_at: lastUpdatedAt,
    current_url: lastSeenUrl,
    time_zone: timezone,
    ip: lastIpAddress,
    metadata = {},
  } = customer;
  const hasMetadata = !!metadata && Object.keys(metadata).length > 0;
  const formattedTimezone =
    timezone && timezone.length ? timezone.split('_').join(' ') : null;

  return (
    <Box
      sx={{
        width: '100%',
        minHeight: '100%',
        bg: 'rgb(245, 245, 245)',
        border: `1px solid rgba(0,0,0,.06)`,
        boxShadow: 'inset rgba(0, 0, 0, 0.1) 0px 0px 4px',
        flex: 1,
      }}
    >
      <Box px={2} py={3} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
        <Box px={2} mb={3}>
          <Text strong>Conversation details</Text>
        </Box>

        <Box
          px={2}
          mb={1}
          sx={{
            maxWidth: '100%',
            overflow: 'hidden',
            whiteSpace: 'nowrap',
            textOverflow: 'ellipsis',
          }}
        >
          <Text type="secondary">ID:</Text>{' '}
          <Tooltip title={conversationId.toLowerCase()} placement="left">
            {conversationId.toLowerCase()}
          </Tooltip>
        </Box>
        <Box px={2} mb={1}>
          <Text type="secondary">Status:</Text>{' '}
          <Tag color={status === 'open' ? colors.primary : colors.red}>
            {status}
          </Tag>
        </Box>

        {false && (
          <DetailsSectionCard>
            <Box mb={2}>
              <Text strong>Tags</Text>
            </Box>
            <Box>Conversation tags</Box>
          </DetailsSectionCard>
        )}
      </Box>

      <Box px={2} py={3}>
        <Box px={2} mb={3}>
          <Text strong>Customer details</Text>
        </Box>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>{name || 'Anonymous User'}</Text>
          </Box>

          <Flex mb={1} sx={{alignItems: 'center'}}>
            <MailOutlined style={{color: colors.primary}} />
            <Box ml={2}>{email || 'Unknown'}</Box>
          </Flex>
          <Flex mb={1} sx={{alignItems: 'center'}}>
            <PhoneOutlined style={{color: colors.primary}} />
            <Box ml={2}>{phone || 'Unknown'}</Box>
          </Flex>
          <Flex mb={1} sx={{alignItems: 'center'}}>
            <UserOutlined style={{color: colors.primary}} />
            <Box
              ml={2}
              sx={{
                maxWidth: '100%',
                overflow: 'hidden',
                whiteSpace: 'nowrap',
                textOverflow: 'ellipsis',
              }}
            >
              <Text type="secondary">ID:</Text>{' '}
              <Tooltip title={externalId || customerId} placement="left">
                {externalId || customerId}
              </Tooltip>
            </Box>
          </Flex>
        </DetailsSectionCard>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>Last seen</Text>
          </Box>
          <Box mb={1}>
            <CalendarOutlined />{' '}
            {lastUpdatedAt
              ? dayjs.utc(lastUpdatedAt).format('MMMM DD, YYYY')
              : 'N/A'}{' '}
            <Text type="secondary">at</Text>
          </Box>
          <Box mb={1}>
            {lastSeenUrl ? (
              <a href={lastSeenUrl} target="_blank" rel="noopener noreferrer">
                {pathname && pathname.length > 1 ? pathname : lastSeenUrl}
              </a>
            ) : (
              <Text>Unknown URL</Text>
            )}
          </Box>
        </DetailsSectionCard>

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>First seen</Text>
          </Box>
          <Box>
            <CalendarOutlined />{' '}
            {createdAt ? dayjs.utc(createdAt).format('MMMM DD, YYYY') : 'N/A'}
          </Box>
        </DetailsSectionCard>

        {hasMetadata && (
          <DetailsSectionCard>
            <Box mb={2}>
              <Text strong>Metadata</Text>
            </Box>

            {Object.entries(metadata).map(([key, value]) => {
              return (
                <Box key={key} mb={1}>
                  <Text type="secondary">{key}:</Text> {String(value)}
                </Box>
              );
            })}
          </DetailsSectionCard>
        )}

        <DetailsSectionCard>
          <Box mb={2}>
            <Text strong>Device</Text>
          </Box>
          {formattedTimezone && (
            <Box mb={1}>
              <GlobalOutlined /> {formattedTimezone}
            </Box>
          )}
          <Box mb={1}>{[os, browser].join(' · ') || 'Unknown'}</Box>
          <Box mb={1}>
            <Text type="secondary">IP:</Text> {lastIpAddress || 'Unknown'}
          </Box>
        </DetailsSectionCard>

        {false && (
          <DetailsSectionCard>
            <Box mb={2}>
              <Text strong>Tags</Text>
            </Box>
            <Box>Customer tags</Box>
          </DetailsSectionCard>
        )}
      </Box>
    </Box>
  );
};

export default ConversationDetailsSidebar;
