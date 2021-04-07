import React from 'react';
import {Link} from 'react-router-dom';
import dayjs from 'dayjs';
import utc from 'dayjs/plugin/utc';
import {Box, Flex} from 'theme-ui';
import {Badge, Button, Divider, colors, Text, Title, Tooltip} from '../common';
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
import CustomerDetailsCard from './CustomerDetailsCard';

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
    email,
    name,
    browser,
    os,
    phone,
    pathname,
    title,
    company,
    id: customerId,
    external_id: externalId,
    created_at: createdAt,
    last_seen_at: lastSeenAt,
    current_url: currentUrl,
    time_zone: timezone,
    ip: lastIpAddress,
    metadata = {},
  } = customer;
  const hasMetadata = !!metadata && Object.keys(metadata).length > 0;

  return (
    <CustomerDetailsCard sx={{minWidth: '320px'}}>
      <Box p={3}>
        <Title level={4}>{title}</Title>

        <Divider dashed />

        <CustomerDetailsSection title="Basic">
          <CustomerDetailsProperty
            Icon={UserOutlined}
            name="ID"
            value={externalId || customerId}
          />
          <CustomerDetailsProperty
            Icon={UserOutlined}
            name="Name"
            value={name}
          />
          <CustomerDetailsProperty
            Icon={MailOutlined}
            name="Email"
            value={email}
          />
          <CustomerDetailsProperty
            Icon={PhoneOutlined}
            name="Phone"
            value={phone}
          />
        </CustomerDetailsSection>

        <Divider dashed />

        <CustomerDetailsSection title="Activity">
          <CustomerDetailsProperty
            Icon={CalendarOutlined}
            name="First Seen"
            value={createdAt && dayjs.utc(createdAt).format('MMMM DD, YYYY')}
          />
          <CustomerDetailsProperty
            Icon={CalendarOutlined}
            name="Last Seen"
            value={getLastSeenValue({isOnline: !!session, lastSeenAt})}
          />
          <CustomerDetailsProperty
            Icon={LinkOutlined}
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

        <Divider dashed />

        <CustomerDetailsSection title="Device">
          <CustomerDetailsProperty
            Icon={GlobalOutlined}
            name="Timezone"
            value={getTimezoneValue(timezone)}
          />
          <CustomerDetailsProperty
            Icon={DesktopOutlined}
            name="Browser"
            value={browser}
          />
          <CustomerDetailsProperty
            Icon={DesktopOutlined}
            name="OS"
            value={os}
          />
          <CustomerDetailsProperty
            Icon={DesktopOutlined}
            name="IP"
            value={lastIpAddress}
          />
        </CustomerDetailsSection>

        <Divider dashed />

        <CompanyDetailsSection company={company} />

        <Divider dashed />

        {hasMetadata && (
          <>
            <CustomerDetailsSection title="Metadata">
              {Object.entries(metadata).map(([key, value]) => (
                <CustomerDetailsProperty
                  Icon={InfoCircleOutlined}
                  key={key}
                  name={key}
                  value={value}
                />
              ))}
            </CustomerDetailsSection>
            <Divider dashed />
          </>
        )}

        <CustomerDetailsSection title="Tags">
          <SidebarCustomerTags customerId={customerId} />
        </CustomerDetailsSection>
      </Box>
    </CustomerDetailsCard>
  );
};

const CompanyDetailsSection = ({company}: {company: Company | undefined}) => {
  let body;

  if (company) {
    const {
      id: companyId,
      name,
      website_url: websiteUrl,
      slack_channel_id: slackChannelId,
      slack_channel_name: slackChannelName,
    } = company;

    body = (
      <>
        <CustomerDetailsProperty
          Icon={TeamOutlined}
          name="Name"
          value={<Link to={`/companies/${companyId}`}>{name}</Link>}
        />
        <CustomerDetailsProperty
          Icon={LinkOutlined}
          name="Website"
          value={websiteUrl}
        />
        <CustomerDetailsProperty
          Icon={LinkOutlined}
          name="Slack Channel"
          value={
            slackChannelId &&
            slackChannelName && (
              <a
                href={`https://slack.com/app_redirect?channel=${slackChannelId}`}
                target="_blank"
                rel="noopener noreferrer"
              >
                {slackChannelName}
              </a>
            )
          }
        />
      </>
    );
  } else {
    // TODO: add ability to link customer to company
    body = <Text>Customer is not linked to a company.</Text>;
  }

  return (
    <CustomerDetailsSection title="Company">{body}</CustomerDetailsSection>
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
  Icon,
  name,
  value,
}: {
  Icon: React.ComponentType<any>;
  name: string;
  value: any;
}) => {
  let valueComponent;

  if (React.isValidElement(value)) {
    valueComponent = value;
  } else {
    valueComponent = <Text>{value || 'Unknown'}</Text>;
  }

  return (
    <Flex mb={1} sx={{alignItems: 'center'}}>
      <Icon style={{color: colors.primary}} />
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
      {valueComponent}
    </Flex>
  );
};

const getLastSeenValue = ({
  isOnline,
  lastSeenAt,
}: {
  isOnline: boolean | undefined;
  lastSeenAt: string | undefined;
}): string | JSX.Element | undefined => {
  if (isOnline) {
    return <Badge status="processing" text="Online now" />;
  } else if (lastSeenAt) {
    return dayjs.utc(lastSeenAt).format('MMMM DD, YYYY');
  }
};

const getLastSeenURLValue = ({
  currentUrl,
  pathname,
}: {
  currentUrl: string | undefined;
  pathname: string | undefined;
}): JSX.Element | undefined => {
  if (currentUrl) {
    return (
      <Tooltip title={currentUrl}>
        <a href={currentUrl} target="_blank" rel="noopener noreferrer">
          {pathname && pathname.length > 1 ? pathname : currentUrl}
        </a>
      </Tooltip>
    );
  }
};

const getTimezoneValue = (timezone: string | undefined): string | undefined => {
  if (timezone) {
    return timezone.split('_').join(' ');
  }
};

export default CustomerDetailsSidebar;
