import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {Badge, Button, Card, Divider, colors, Text, Tooltip} from '../common';
import {
  CalendarOutlined,
  DesktopOutlined,
  GlobalOutlined,
  InfoCircleOutlined,
  LinkOutlined,
  MailOutlined,
  PhoneOutlined,
  TeamOutlined,
  UserOutlined,
  VideoCameraOutlined,
} from '../icons';
import {SidebarCustomerTags} from '../conversations/SidebarTagSection';
import {BrowserSession, Company, Customer} from '../../types';

// TODO: create date utility methods so we don't have to do this everywhere
dayjs.extend(utc);

export const CustomerDetailsSidebar = ({
  customer,
  session,
}: {
  customer: Customer;
  session: BrowserSession | null;
}) => {
  const {
    browser,
    company,
    created_at: createdAt,
    current_url: currentUrl,
    email,
    external_id: externalId,
    id: customerId,
    ip: lastIpAddress,
    last_seen_at: lastSeenAt,
    metadata = {},
    name,
    os,
    pathname,
    phone,
    time_zone: timezone,
  } = customer;
  const hasMetadata = !!metadata && Object.keys(metadata).length > 0;

  return (
    <Card sx={{minWidth: 320, maxWidth: 360}}>
      <Box p={3}>
        <CustomerDetailsSection title="Basic">
          <CustomerDetailsProperty
            icon={<UserOutlined style={{color: colors.primary}} />}
            name="ID"
            value={
              <CustomerDetailsPropertyValue value={externalId || customerId} />
            }
          />
          <CustomerDetailsProperty
            icon={<UserOutlined style={{color: colors.primary}} />}
            name="Name"
            value={<CustomerDetailsPropertyValue value={name} />}
          />
          <CustomerDetailsProperty
            icon={<MailOutlined style={{color: colors.primary}} />}
            name="Email"
            value={<CustomerDetailsPropertyValue value={email} />}
          />
          <CustomerDetailsProperty
            icon={<PhoneOutlined style={{color: colors.primary}} />}
            name="Phone"
            value={<CustomerDetailsPropertyValue value={phone} />}
          />
        </CustomerDetailsSection>

        <Divider />

        <CustomerDetailsSection title="Activity">
          <CustomerDetailsProperty
            icon={<CalendarOutlined style={{color: colors.primary}} />}
            name="First Seen"
            value={
              <CustomerDetailsPropertyValue
                value={
                  createdAt
                    ? dayjs.utc(createdAt).format('MMMM DD, YYYY')
                    : null
                }
              />
            }
          />
          <CustomerDetailsProperty
            icon={<CalendarOutlined style={{color: colors.primary}} />}
            name="Last Seen"
            value={getLastSeenValue({isOnline: !!session, lastSeenAt})}
          />
          <CustomerDetailsProperty
            icon={<LinkOutlined style={{color: colors.primary}} />}
            name="Last Seen URL"
            value={getLastSeenURLValue({currentUrl, pathname})}
          />
          {session && (
            <Box mt={3}>
              <Link to={`/sessions/live/${session.id}`}>
                <Button
                  type="primary"
                  icon={<VideoCameraOutlined />}
                  block
                  ghost
                >
                  View live
                </Button>
              </Link>
            </Box>
          )}
        </CustomerDetailsSection>

        <Divider />

        <CustomerDetailsSection title="Device">
          <CustomerDetailsProperty
            icon={<GlobalOutlined style={{color: colors.primary}} />}
            name="Timezone"
            value={getTimezoneValue(timezone)}
          />
          <CustomerDetailsProperty
            icon={<DesktopOutlined style={{color: colors.primary}} />}
            name="Browser"
            value={<CustomerDetailsPropertyValue value={browser} />}
          />

          <CustomerDetailsProperty
            icon={<DesktopOutlined style={{color: colors.primary}} />}
            name="OS"
            value={<CustomerDetailsPropertyValue value={os} />}
          />
          <CustomerDetailsProperty
            icon={<DesktopOutlined style={{color: colors.primary}} />}
            name="IP"
            value={<CustomerDetailsPropertyValue value={lastIpAddress} />}
          />
        </CustomerDetailsSection>

        <Divider />

        <CompanyDetailsSection company={company} />

        <Divider />

        {hasMetadata && (
          <>
            <CustomerDetailsSection title="Metadata">
              {Object.entries(metadata).map(([key, value]) => (
                <CustomerDetailsProperty
                  icon={<InfoCircleOutlined style={{color: colors.primary}} />}
                  key={key}
                  name={key}
                  value={<CustomerDetailsPropertyValue value={value} />}
                />
              ))}
            </CustomerDetailsSection>
            <Divider />
          </>
        )}

        <CustomerDetailsSection title="Tags">
          <SidebarCustomerTags customerId={customerId} />
        </CustomerDetailsSection>
      </Box>
    </Card>
  );
};

const CustomerDetailsDefaultPropertyValue = ({
  defaultValue = 'Unknown',
}: {
  defaultValue?: string;
}) => <Text>{defaultValue}</Text>;

const CustomerDetailsPropertyValue = ({
  value,
  defaultValue,
}: {
  value?: any;
  defaultValue?: string;
}) => {
  if (value != null) {
    return <Text>{String(value)}</Text>;
  } else {
    return <CustomerDetailsDefaultPropertyValue defaultValue={defaultValue} />;
  }
};

const CompanyDetailsSection = ({company}: {company?: Company}) => {
  const title = 'Company';

  if (!company) {
    return (
      <CustomerDetailsSection title={title}>
        <Text>Customer is not linked to a company.</Text>
      </CustomerDetailsSection>
    );
  }

  const {
    id: companyId,
    name,
    website_url: websiteUrl,
    slack_channel_id: slackChannelId,
    slack_channel_name: slackChannelName,
  } = company;

  let slackPropertyValue;

  if (slackChannelName && slackChannelId) {
    slackPropertyValue = (
      <a
        href={`https://slack.com/app_redirect?channel=${slackChannelId}`}
        target="_blank"
        rel="noopener noreferrer"
      >
        {slackChannelName}
      </a>
    );
  } else {
    slackPropertyValue = <CustomerDetailsDefaultPropertyValue />;
  }

  return (
    <CustomerDetailsSection title={title}>
      <CustomerDetailsProperty
        icon={<TeamOutlined style={{color: colors.primary}} />}
        name="Name"
        value={<Link to={`/companies/${companyId}`}>{name}</Link>}
      />
      <CustomerDetailsProperty
        icon={<LinkOutlined style={{color: colors.primary}} />}
        name="Website"
        value={
          websiteUrl ? (
            <a href={websiteUrl} target="_blank" rel="noopener noreferrer">
              {websiteUrl}
            </a>
          ) : (
            <Text>N/A</Text>
          )
        }
      />
      <CustomerDetailsProperty
        icon={<LinkOutlined style={{color: colors.primary}} />}
        name="Slack Channel"
        value={slackPropertyValue}
      />
    </CustomerDetailsSection>
  );
};

export const CustomerDetailsSection = ({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) => {
  return (
    <Box>
      <Box mb={2}>
        <Text strong>{title}</Text>
      </Box>
      {children}
    </Box>
  );
};

const CustomerDetailsProperty = ({
  icon,
  name,
  value,
}: {
  icon: JSX.Element;
  name: string;
  value: JSX.Element;
}) => {
  return (
    <Flex mb={1} sx={{alignItems: 'center'}}>
      {icon}
      <Box
        ml={2}
        mr={2}
        sx={{
          maxWidth: '100%',
          overflow: 'hidden',
          whiteSpace: 'nowrap',
          textOverflow: 'ellipsis',
        }}
      >
        <Text type="secondary">{name}</Text>
      </Box>
      {value}
    </Flex>
  );
};

const getLastSeenValue = ({
  isOnline,
  lastSeenAt,
}: {
  isOnline?: boolean;
  lastSeenAt?: string;
}): JSX.Element => {
  if (isOnline) {
    return <Badge status="processing" text="Online now" />;
  } else if (lastSeenAt) {
    return <Text>{dayjs.utc(lastSeenAt).format('MMMM DD, YYYY')}</Text>;
  } else {
    return <CustomerDetailsDefaultPropertyValue />;
  }
};

const getLastSeenURLValue = ({
  currentUrl,
  pathname,
}: {
  currentUrl?: string;
  pathname?: string;
}): JSX.Element => {
  if (currentUrl) {
    return (
      <Tooltip title={currentUrl}>
        <a
          style={{
            maxWidth: '100%',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
          }}
          href={currentUrl}
          target="_blank"
          rel="noopener noreferrer"
        >
          {pathname && pathname.length > 1 ? pathname : currentUrl}
        </a>
      </Tooltip>
    );
  } else {
    return <CustomerDetailsDefaultPropertyValue />;
  }
};

const getTimezoneValue = (timezone?: string): JSX.Element => {
  if (timezone) {
    return <Text>{timezone.split('_').join(' ')}</Text>;
  } else {
    return <CustomerDetailsDefaultPropertyValue />;
  }
};

export default CustomerDetailsSidebar;
