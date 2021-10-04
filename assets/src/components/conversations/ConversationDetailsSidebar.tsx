import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {FRONTEND_BASE_URL} from '../../config';
import {
  colors,
  notification,
  Badge,
  Button,
  Card,
  Input,
  Paragraph,
  Tag,
  Text,
  Tooltip,
  Popover,
} from '../common';
import {
  CalendarOutlined,
  GlobalOutlined,
  InfoCircleOutlined,
  MailOutlined,
  PhoneOutlined,
  UserOutlined,
} from '../icons';
import {
  SidebarCustomerTags,
  SidebarConversationTags,
} from './SidebarTagSection';
import SidebarCustomerNotes from './SidebarCustomerNotes';
import SidebarCustomerIssues from './SidebarCustomerIssues';
import RelatedCustomerConversations from './RelatedCustomerConversations';
import SlackConversationThreads from './SlackConversationThreads';
import CustomerActiveSessions from '../customers/CustomerActiveSessions';
import CustomerHubspotInfo from '../customers/CustomerHubspotInfo';
import CustomerIntercomInfo from '../customers/CustomerIntercomInfo';
import CustomerCompanyDetails from '../customers/CustomerCompanyDetails';
import * as API from '../../api';
import {Conversation, Customer} from '../../types';
import {download} from '../../utils';
import logger from '../../logger';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

export const DetailsSectionCard = ({children}: {children: any}) => {
  return <Card sx={{p: 2, my: 2}}>{children}</Card>;
};

export const CustomerDetails = ({
  customer,
  isOnline,
}: {
  customer: Customer;
  isOnline?: boolean;
}) => {
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

  const exportCustomerData = async () => {
    try {
      const customer = await API.fetchCustomer(customerId, {
        expand: ['company', 'conversations', 'messages', 'tags', 'notes'],
      });

      download(customer, `customer-${customerId}`);
    } catch (err) {
      logger.error('Failed to export customer:', err);
    }
  };

  return (
    <Box>
      <DetailsSectionCard>
        <Flex
          mb={2}
          sx={{justifyContent: 'space-between', alignItems: 'baseline'}}
        >
          <Link to={`/customers/${customer.id}`}>
            <Text strong>{name || 'Anonymous User'}</Text>
          </Link>

          <Popover
            placement="left"
            content={
              <Box>
                <Button
                  type="primary"
                  style={{width: '100%'}}
                  onClick={exportCustomerData}
                >
                  Download
                </Button>
              </Box>
            }
            title="Export customer data as JSON"
          >
            <Box>
              <InfoCircleOutlined
                style={{color: colors.secondary, opacity: 0.8}}
              />
            </Box>
          </Popover>
        </Flex>

        <Flex mb={1} sx={{alignItems: 'center'}}>
          <MailOutlined style={{color: colors.primary}} />
          <Box
            ml={2}
            sx={{
              maxWidth: '100%',
              overflow: 'hidden',
              whiteSpace: 'nowrap',
              textOverflow: 'ellipsis',
            }}
          >
            <Tooltip title={email} placement="left">
              <Text>{email || 'Unknown'}</Text>
            </Tooltip>
          </Box>
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

      {isOnline ? (
        <DetailsSectionCard>
          <Flex mb={2} sx={{justifyContent: 'space-between'}}>
            <Text strong>Last seen</Text>
            <Badge status="processing" text="Online now" />
          </Flex>
          <Box mb={2}>
            <CustomerActiveSessions customerId={customerId} />
          </Box>
          <Text type="secondary">Session started at</Text>
          <Box mb={1}>
            {lastSeenUrl ? (
              <Tooltip title={lastSeenUrl}>
                <a href={lastSeenUrl} target="_blank" rel="noopener noreferrer">
                  {pathname && pathname.length > 1 ? pathname : lastSeenUrl}
                </a>
              </Tooltip>
            ) : (
              <Text>Unknown URL</Text>
            )}
          </Box>
        </DetailsSectionCard>
      ) : (
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
              <Tooltip title={lastSeenUrl}>
                <a href={lastSeenUrl} target="_blank" rel="noopener noreferrer">
                  {pathname && pathname.length > 1 ? pathname : lastSeenUrl}
                </a>
              </Tooltip>
            ) : (
              <Text>Unknown URL</Text>
            )}
          </Box>
        </DetailsSectionCard>
      )}

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
        <Box mb={1}>
          {[os, browser].filter(Boolean).join(' · ') || 'Unknown'}
        </Box>
        <Box mb={1}>
          <Text type="secondary">IP:</Text> {lastIpAddress || 'Unknown'}
        </Box>
      </DetailsSectionCard>

      <CustomerCompanyDetails customerId={customerId} />
      <CustomerHubspotInfo customer={customer} />
      <CustomerIntercomInfo customer={customer} />

      <DetailsSectionCard>
        <Box mb={2}>
          <Link to={`/customers/${customer.id}?tab=issues`}>
            <Text strong>Linked issues</Text>
          </Link>
        </Box>
        <SidebarCustomerIssues customerId={customerId} />
      </DetailsSectionCard>

      <DetailsSectionCard>
        <Box mb={2}>
          <Link to={`/customers/${customer.id}?tab=notes`}>
            <Text strong>Customer notes</Text>
          </Link>
        </Box>

        <SidebarCustomerNotes customerId={customerId} />
      </DetailsSectionCard>

      <DetailsSectionCard>
        <Box mb={2}>
          <Text strong>Customer tags</Text>
        </Box>
        <SidebarCustomerTags customerId={customerId} />
      </DetailsSectionCard>
    </Box>
  );
};

export const CustomerDetailsSection = ({
  customer,
  isOnline,
}: {
  customer: Customer;
  isOnline?: boolean;
}) => {
  return (
    <Box px={2} py={3}>
      <Box px={2} mb={3}>
        <Text strong>Customer details</Text>
      </Box>

      <CustomerDetails customer={customer} isOnline={isOnline} />
    </Box>
  );
};

const autoSelectAndCopyInput = (el: any) => {
  const input = el.target || el.currentTarget;

  if (!input || !input.focus || !input.select) {
    return;
  }

  input.focus();
  input.select();

  if (document.queryCommandSupported('copy')) {
    document.execCommand('copy');
  }
};

const openShareConversationUrlNotification = (url: string) => {
  return notification.open({
    message: 'Share this conversation',
    description: (
      <Box>
        <Paragraph>Use the URL below to share this conversation.</Paragraph>
        <Box mb={3}>
          <Input type="text" value={url} onFocus={autoSelectAndCopyInput} />
        </Box>
        <Text type="secondary">This link will only be valid for 24 hours.</Text>
      </Box>
    ),
    duration: null,
  });
};

const ConversationDetails = ({conversation}: {conversation: Conversation}) => {
  const {id: conversationId, status, source} = conversation;

  const share = () => {
    API.generateShareConversationToken(conversationId)
      .then(({token}) => {
        const url = `${FRONTEND_BASE_URL}/share?cid=${conversationId}&token=${token}`;

        return openShareConversationUrlNotification(url);
      })
      .catch((err) => {
        logger.error('Failed to generate share token!', err);
      });
  };

  return (
    <Box px={2} py={3} sx={{borderTop: '1px solid rgba(0,0,0,.06)'}}>
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
          <Text>{conversationId.toLowerCase()}</Text>
        </Tooltip>
      </Box>
      <Box px={2} mb={1}>
        <Text type="secondary">Status:</Text>{' '}
        <Tag color={status === 'open' ? colors.primary : colors.red}>
          {status}
        </Tag>
      </Box>
      <Box px={2} mb={3}>
        <Text type="secondary">Source:</Text> <Tag>{source}</Tag>
      </Box>

      <DetailsSectionCard>
        <Box mb={2}>
          <Text strong>Conversation tags</Text>
        </Box>
        <SidebarConversationTags conversationId={conversationId} />
      </DetailsSectionCard>

      <DetailsSectionCard>
        <Box mb={2}>
          <Text strong>Latest conversations</Text>
        </Box>
        <Box mx={-2} mb={-2}>
          <RelatedCustomerConversations conversationId={conversationId} />
        </Box>
      </DetailsSectionCard>

      <DetailsSectionCard>
        <Box mb={2}>
          <Text strong>Slack threads</Text>
        </Box>
        <SlackConversationThreads conversationId={conversationId} />
      </DetailsSectionCard>

      <Box px={2} mt={3} mb={3}>
        <Button type="primary" block ghost onClick={share}>
          Share conversation
        </Button>
      </Box>
    </Box>
  );
};

type Props = {
  customer: Customer;
  conversation?: Conversation;
  isOnline?: boolean;
};

const ConversationDetailsSidebar = ({
  customer,
  conversation,
  isOnline,
}: Props) => {
  return (
    <Box
      sx={{
        width: '100%',
        minHeight: '100%',
        bg: 'rgb(250, 250, 250)',
        border: `1px solid rgba(0,0,0,.06)`,
        boxShadow: 'inset rgba(0, 0, 0, 0.1) 0px 0px 4px',
        flex: 1,
      }}
    >
      <CustomerDetailsSection customer={customer} isOnline={isOnline} />
      {conversation && <ConversationDetails conversation={conversation} />}
    </Box>
  );
};

export default ConversationDetailsSidebar;
