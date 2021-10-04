import React from 'react';
import {Link} from 'react-router-dom';
import {Image} from 'theme-ui';
import {Box, Flex} from 'theme-ui';
import {Button, Text} from '../common';
import {LinkOutlined, TeamOutlined} from '../icons';
import * as API from '../../api';
import {Company} from '../../types';
import logger from '../../logger';
import {generateSlackChannelUrl} from '../companies/support';
import {DetailsSectionCard} from '../conversations/ConversationDetailsSidebar';

export const CustomerCompanyDetails = ({customerId}: {customerId: string}) => {
  const [loading, setLoading] = React.useState(false);
  const [company, setCompany] = React.useState<Company | null>(null);

  React.useEffect(() => {
    setLoading(true);

    API.fetchCustomer(customerId, {expand: ['company']})
      .then((customer) => {
        const {company} = customer;

        setCompany(company);
      })
      .catch((err) => logger.error('Error retrieving company:', err))
      .then(() => setLoading(false));
  }, [customerId]);

  if (loading || !company) {
    return null;
  }

  const {
    id: companyId,
    name = 'Unknown',
    website_url: websiteUrl,
    slack_channel_name: slackChannelName,
  } = company;
  const slackChannelUrl = generateSlackChannelUrl(company);

  return (
    <DetailsSectionCard>
      <Flex mb={2} sx={{alignItems: 'center', justifyContent: 'space-between'}}>
        <Text strong>Company</Text>
        <Link to={`/companies/${companyId}`}>
          <Button size="small">View</Button>
        </Link>
      </Flex>
      <Box mb={1}>
        <TeamOutlined /> {name}
      </Box>
      {websiteUrl && (
        <Box mb={1}>
          <LinkOutlined /> {websiteUrl || 'Unknown'}
        </Box>
      )}
      {slackChannelUrl && slackChannelName && (
        <Box mb={1}>
          <Image src="/slack.svg" alt="Slack" sx={{height: 16, mr: 1}} />
          <a href={slackChannelUrl} target="_blank" rel="noopener noreferrer">
            {slackChannelName}
          </a>
        </Box>
      )}
    </DetailsSectionCard>
  );
};

export default CustomerCompanyDetails;
