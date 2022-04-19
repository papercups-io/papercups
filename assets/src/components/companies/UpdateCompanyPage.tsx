import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Input, Select, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import {Company, SlackAuthorization} from '../../types';
import logger from '../../logger';

type Props = RouteComponentProps<{id: string}>;
type State = {
  loading: boolean;
  saving: boolean;
  company: Company | null;
  name: string;
  description: string;
  websiteUrl: string;
  slackChannelId: string;
  slackChannelName: string;
  slackTeamId: string;
  slackTeamName: string;
  authorizations: Array<any>;
  channels: Array<any>;
};

class UpdateCompanyPage extends React.Component<Props, State> {
  state: State = {
    loading: true,
    saving: false,
    company: null,
    name: '',
    description: '',
    websiteUrl: '',
    slackChannelId: '',
    slackChannelName: '',
    slackTeamId: '',
    slackTeamName: '',
    authorizations: [],
    channels: [],
  };

  async componentDidMount() {
    try {
      const {id: companyId} = this.props.match.params;
      const company = await API.fetchCompany(companyId);
      const {
        name,
        description,
        website_url: websiteUrl,
        slack_channel_id: slackChannelId,
        slack_channel_name: slackChannelName,
        slack_team_id: slackTeamId,
        slack_team_name: slackTeamName,
      } = company;

      const authorizations = await API.listSlackAuthorizations('support');

      if (slackTeamId) {
        const channels = await API.fetchSlackChannels({
          team_id: slackTeamId,
        });

        this.setState({channels});
      }

      this.setState({
        company,
        name,
        description,
        websiteUrl,
        slackChannelId,
        slackChannelName,
        slackTeamId,
        slackTeamName,
        authorizations,
        loading: false,
      });
    } catch (err) {
      logger.error('Error loading company for editing:', err);

      this.setState({loading: false});
    }
  }

  handleResetCompanyFields = async () => {
    try {
      const {id: companyId} = this.props.match.params;
      const company = await API.fetchCompany(companyId);
      const {
        name,
        description,
        website_url: websiteUrl,
        slack_channel_id: slackChannelId,
        slack_channel_name: slackChannelName,
      } = company;

      this.setState({
        company,
        name,
        description,
        websiteUrl,
        slackChannelId,
        slackChannelName,
      });
    } catch (err) {
      logger.error('Error resetting company fields:', err);
    }
  };

  handleChangeSlackTeam = async (value: string, record: any) => {
    const {company, slackTeamId} = this.state;

    if (value !== slackTeamId) {
      const currentSlackTeamId = company?.slack_team_id;
      const currentSlackChannelId = company?.slack_channel_id ?? '';
      const currentSlackChannelName = company?.slack_channel_name ?? '';

      this.setState({
        slackTeamId: value || '',
        slackTeamName: record?.label || '',
        slackChannelId:
          currentSlackTeamId === value ? currentSlackChannelId : '',
        slackChannelName:
          currentSlackTeamId === value ? currentSlackChannelName : '',
      });

      const channels = await API.fetchSlackChannels({
        team_id: value,
      });

      this.setState({channels});
    } else {
      this.setState({
        slackTeamId: value || '',
        slackTeamName: record?.label || '',
      });
    }
  };

  handleUpdateCompany = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    try {
      const {id: companyId} = this.props.match.params;
      const {
        name,
        description,
        websiteUrl,
        slackChannelId,
        slackChannelName,
        slackTeamId,
        slackTeamName,
      } = this.state;
      const company = await API.updateCompany(companyId, {
        name,
        description,
        website_url: websiteUrl,
        slack_channel_id: slackChannelId,
        slack_channel_name: slackChannelName,
        slack_team_id: slackTeamId,
        slack_team_name: slackTeamName,
      });

      this.setState({company});

      return this.props.history.push(`/companies/${companyId}`);
    } catch (err) {
      logger.error('Error updating company:', err);
    }
  };

  render() {
    const {id: companyId} = this.props.match.params;
    const {
      loading,
      name,
      description,
      websiteUrl,
      slackChannelId,
      slackTeamId,
      channels = [],
      authorizations = [],
      saving,
    } = this.state;

    return (
      <Box p={4} sx={{maxWidth: 720}}>
        <Box mb={4}>
          <Link to={`/companies/${companyId}`}>
            <Button icon={<ArrowLeftOutlined />}>Back to company</Button>
          </Link>
        </Box>

        <Title level={3}>Edit company information</Title>

        <Box my={4} sx={{maxWidth: 400}}>
          <form onSubmit={this.handleUpdateCompany}>
            <Box mb={3}>
              <label htmlFor="name">Company name</label>
              <Input
                id="name"
                type="text"
                disabled={loading}
                value={name}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({name: e.target.value})
                }
              />
            </Box>
            <Box mb={3}>
              <label htmlFor="description">Company description</label>
              <Input
                id="description"
                type="text"
                disabled={loading}
                value={description}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({description: e.target.value})
                }
              />
            </Box>
            <Box mb={3}>
              <label htmlFor="website_url">Company website</label>
              <Input
                id="website_url"
                type="text"
                disabled={loading}
                value={websiteUrl}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({websiteUrl: e.target.value})
                }
              />
            </Box>

            <Box mb={3}>
              <label htmlFor="slack_channel_id">Company Slack workspace</label>

              <Select
                style={{width: '100%'}}
                placeholder="Select Slack workspace"
                showSearch
                allowClear
                disabled={loading}
                value={slackTeamId || undefined}
                onChange={this.handleChangeSlackTeam}
                options={authorizations.map((auth: SlackAuthorization) => {
                  const {team_id: id, team_name: name} = auth;

                  return {id, key: id, label: name, value: id};
                })}
                filterOption={(input: string, option: any) => {
                  const {label = ''} = option;

                  return (
                    label.toLowerCase().indexOf(input.toLowerCase()) !== -1
                  );
                }}
              />
            </Box>

            <Box mb={3}>
              <label htmlFor="slack_channel_id">Company Slack channel</label>

              <Select
                style={{width: '100%'}}
                placeholder="Select Slack channel"
                showSearch
                allowClear
                disabled={loading}
                value={slackChannelId || undefined}
                onChange={(value: string, record: any) => {
                  this.setState({
                    slackChannelId: value || '',
                    slackChannelName: record?.label || '',
                  });
                }}
                options={channels.map((channel: any) => {
                  const {id, name} = channel;

                  return {id, key: id, label: `#${name}`, value: id};
                })}
                filterOption={(input: string, option: any) => {
                  const {label = ''} = option;

                  return (
                    label.toLowerCase().indexOf(input.toLowerCase()) !== -1
                  );
                }}
              />
            </Box>

            <Flex my={4}>
              <Box mr={2}>
                <Button
                  disabled={loading}
                  onClick={this.handleResetCompanyFields}
                >
                  Reset
                </Button>
              </Box>

              <Button type="primary" htmlType="submit" loading={saving}>
                Update
              </Button>
            </Flex>
          </form>
        </Box>
      </Box>
    );
  }
}

export default UpdateCompanyPage;
