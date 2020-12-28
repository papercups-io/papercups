import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Divider,
  Paragraph,
  Popconfirm,
  Result,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {sleep} from '../../utils';
import Spinner from '../Spinner';
import logger from '../../logger';
import CustomersTable from '../customers/CustomersTable';

const formatSlackChannel = (name: string) => {
  return name.startsWith('#') ? name : `#${name}`;
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  deleting: boolean;
  company: any;
  customers: Array<any>;
};

class CompanyDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    deleting: false,
    company: null,
    customers: [],
  };

  async componentDidMount() {
    try {
      const {id: companyId} = this.props.match.params;
      const company = await API.fetchCompany(companyId);
      const customers = await API.fetchCustomers({company_id: companyId});

      this.setState({company, customers, loading: false});
    } catch (err) {
      logger.error('Error loading company!', err);

      this.setState({loading: false});
    }
  }

  handleDeleteCompany = async () => {
    try {
      this.setState({deleting: true});
      const {id: companyId} = this.props.match.params;
      await API.deleteCompany(companyId);
      await sleep(1000);

      this.props.history.push('/companies');
    } catch (err) {
      logger.error('Error deleting company!', err);

      this.setState({deleting: false});
    }
  };

  render() {
    const {loading, deleting, company, customers = []} = this.state;

    if (loading) {
      return (
        <Flex
          sx={{
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center',
            height: '100%',
          }}
        >
          <Spinner size={40} />
        </Flex>
      );
    } else if (!company) {
      return <Result status="error" title="Error retrieving company" />;
    }

    const {
      name,
      description,
      website_url: websiteUrl,
      slack_channel_id: slackChannelId,
      slack_channel_name: slackChannelName,
    } = company;

    return (
      <Box p={4}>
        <Flex
          mb={4}
          sx={{justifyContent: 'space-between', alignItems: 'center'}}
        >
          <Link to="/companies">
            <Button icon={<ArrowLeftOutlined />}>Back to companies</Button>
          </Link>

          {(!customers || customers.length === 0) && (
            <Popconfirm
              title="Are you sure you want to delete this company?"
              okText="Yes"
              cancelText="No"
              placement="bottomLeft"
              onConfirm={this.handleDeleteCompany}
            >
              <Button danger loading={deleting}>
                Delete company
              </Button>
            </Popconfirm>
          )}
        </Flex>

        <Title level={3}>{name}</Title>

        {description && <Paragraph>{description}</Paragraph>}

        <Box mb={2}>
          <Box>
            <Text strong>Website</Text>
          </Box>

          <Paragraph>
            {websiteUrl ? (
              <a href={websiteUrl} target="_blank" rel="noopener noreferrer">
                {websiteUrl}
              </a>
            ) : (
              'N/A'
            )}
          </Paragraph>
        </Box>

        {slackChannelId && slackChannelName && (
          <Box mb={2}>
            <Box>
              <Text strong>Connected Slack Channel</Text>
            </Box>

            <Paragraph>
              {/* TODO: include Slack team ID if necessary */}
              <a
                href={`https://slack.com/app_redirect?channel=${slackChannelId}`}
                target="_blank"
                rel="noopener noreferrer"
              >
                {formatSlackChannel(slackChannelName)}
              </a>
            </Paragraph>
          </Box>
        )}

        <Divider />

        <Title level={4}>People</Title>

        <Box my={3}>
          <CustomersTable
            loading={loading}
            customers={customers}
            currentlyOnline={{}}
            onUpdate={() => Promise.resolve()}
          />
        </Box>
      </Box>
    );
  }
}

export default CompanyDetailsPage;
