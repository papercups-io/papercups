import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {
  colors,
  shadows,
  Button,
  Popconfirm,
  Result,
  Text,
  Title,
} from '../common';
import {ArrowLeftOutlined, DeleteOutlined} from '../icons';
import * as API from '../../api';
import {sleep} from '../../utils';
import Spinner from '../Spinner';
import logger from '../../logger';
import CustomersTable from '../customers/CustomersTable';

const formatSlackChannel = (name: string) => {
  return name.startsWith('#') ? name : `#${name}`;
};

const DetailsSectionCard = ({children}: {children: any}) => {
  return (
    <Box
      p={3}
      mb={3}
      sx={{
        bg: colors.white,
        border: '1px solid rgba(0,0,0,.06)',
        borderRadius: 4,
        boxShadow: shadows.medium,
      }}
    >
      {children}
    </Box>
  );
};

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  deleting: boolean;
  refreshing: boolean;
  company: any;
  customers: Array<any>;
};

class CompanyDetailsPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    deleting: false,
    refreshing: false,
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

  handleRefreshCustomers = async () => {
    this.setState({refreshing: true});

    try {
      const {id: companyId} = this.props.match.params;
      const customers = await API.fetchCustomers({company_id: companyId});

      this.setState({customers, refreshing: false});
    } catch (err) {
      logger.error('Error refreshing customers!', err);

      this.setState({refreshing: false});
    }
  };

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
    const {loading, deleting, refreshing, company, customers = []} = this.state;

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
      external_id: externalId,
      slack_channel_id: slackChannelId,
      slack_channel_name: slackChannelName,
      id: companyId,
    } = company;

    return (
      <Flex
        p={4}
        sx={{
          flexDirection: 'column',
          flex: 1,
          bg: 'rgb(245, 245, 245)',
        }}
      >
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
              <Button danger loading={deleting} icon={<DeleteOutlined />}>
                Delete company
              </Button>
            </Popconfirm>
          )}
        </Flex>

        <Flex sx={{justifyContent: 'space-between', alignItems: 'center'}}>
          <Title level={2}>{name}</Title>

          <Link to={`/companies/${companyId}/edit`}>
            <Button>Edit company information</Button>
          </Link>
        </Flex>

        <Flex>
          <Box sx={{flex: 1, pr: 4}}>
            <DetailsSectionCard>
              <Box mb={3}>
                <Box>
                  <Text strong>Description</Text>
                </Box>

                <Text>{description || 'N/A'}</Text>
              </Box>

              <Box mb={3}>
                <Box>
                  <Text strong>Website</Text>
                </Box>

                <Text>
                  {websiteUrl ? (
                    <a
                      href={websiteUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      {websiteUrl}
                    </a>
                  ) : (
                    'N/A'
                  )}
                </Text>
              </Box>

              <Box>
                <Box>
                  <Text strong>ID</Text>
                </Box>

                <Text>{externalId || 'N/A'}</Text>
              </Box>
            </DetailsSectionCard>

            {slackChannelId && slackChannelName && (
              <DetailsSectionCard>
                <Box>
                  <Text strong>Connected Slack Channel</Text>
                </Box>

                <Text>
                  {/* TODO: include Slack team ID if necessary */}
                  <a
                    href={`https://slack.com/app_redirect?channel=${slackChannelId}`}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    {formatSlackChannel(slackChannelName)}
                  </a>
                </Text>
              </DetailsSectionCard>
            )}

            <DetailsSectionCard>
              <Box>
                <Text strong>Metadata</Text>
              </Box>

              <Text>{'N/A'}</Text>
            </DetailsSectionCard>
          </Box>

          <Box sx={{flex: 3}}>
            <DetailsSectionCard>
              <Box pb={2} sx={{borderBottom: '1px solid rgba(0,0,0,.06)'}}>
                <Title level={4}>People</Title>
              </Box>

              <CustomersTable
                loading={loading || refreshing}
                customers={customers}
                currentlyOnline={{}}
                onUpdate={this.handleRefreshCustomers}
              />
            </DetailsSectionCard>
          </Box>
        </Flex>
      </Flex>
    );
  }
}

export default CompanyDetailsPage;
