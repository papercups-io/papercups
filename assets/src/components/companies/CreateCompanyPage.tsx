import React from 'react';
import {Link, RouteComponentProps} from 'react-router-dom';
import {Box} from 'theme-ui';
import {Button, Input, Select, Title} from '../common';
import {ArrowLeftOutlined} from '../icons';
import * as API from '../../api';
import logger from '../../logger';

type Props = RouteComponentProps<{}>;
type State = {
  submitting: boolean;
  name: string;
  description: string;
  websiteUrl: string;
  slackChannelId: string;
  slackChannelName: string;
  channels: Array<any>;
};

class CreateCompanyPage extends React.Component<Props, State> {
  state: State = {
    submitting: false,
    name: '',
    description: '',
    websiteUrl: '',
    slackChannelId: '',
    slackChannelName: '',
    channels: [],
  };

  async componentDidMount() {
    const shouldFetchSlackChannels = await this.hasSlackAuthorization();

    if (shouldFetchSlackChannels) {
      const channels = await API.fetchSlackChannels();

      this.setState({channels});
    }
  }

  hasSlackAuthorization = async () => {
    try {
      const auth = await API.fetchSlackAuthorization('support');

      return !!auth;
    } catch (err) {
      logger.error('Error fetching Slack authorization:', err);

      return false;
    }
  };

  handleCreateCompany = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    try {
      const {
        name,
        description,
        websiteUrl,
        slackChannelId,
        slackChannelName,
      } = this.state;
      const {id: companyId} = await API.createNewCompany({
        name,
        description,
        website_url: websiteUrl,
        slack_channel_id: slackChannelId,
        slack_channel_name: slackChannelName,
      });

      return this.props.history.push(`/companies/${companyId}`);
    } catch (err) {
      logger.error('Error creating new company:', err);
    }
  };

  render() {
    const {
      name,
      description,
      websiteUrl,
      slackChannelId,
      channels = [],
      submitting,
    } = this.state;

    return (
      <Box p={4} sx={{maxWidth: 720}}>
        <Box mb={4}>
          <Link to="/companies">
            <Button icon={<ArrowLeftOutlined />}>Back to companies</Button>
          </Link>
        </Box>

        <Title level={3}>New company</Title>

        <Box my={4} sx={{maxWidth: 400}}>
          <form onSubmit={this.handleCreateCompany}>
            <Box mb={3}>
              <label htmlFor="name">Company name</label>
              <Input
                id="name"
                type="text"
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
                value={websiteUrl}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                  this.setState({websiteUrl: e.target.value})
                }
              />
            </Box>

            <Box mb={3}>
              <label htmlFor="slack_channel_id">Company Slack channel</label>

              <Select
                style={{width: '100%'}}
                placeholder="Select Slack channel"
                showSearch
                allowClear
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

            <Box my={4}>
              <Button type="primary" htmlType="submit" loading={submitting}>
                Create
              </Button>
            </Box>
          </form>
        </Box>
      </Box>
    );
  }
}

export default CreateCompanyPage;
