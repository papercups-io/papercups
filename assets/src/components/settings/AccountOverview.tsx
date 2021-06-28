import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  Button,
  Container,
  Divider,
  Input,
  Paragraph,
  Text,
  Title,
} from '../common';
import Spinner from '../Spinner';
import WorkingHoursSelector from './WorkingHoursSelector';
import ConversationRemindersSettings from './ConversationRemindersSettings';
import {WorkingHours} from './support';
import * as API from '../../api';
import {Account, AccountSettings, User} from '../../types';
import logger from '../../logger';

type Props = {};
type State = {
  account: Account | null;
  companyName: string;
  companyLogoUrl?: string;
  currentUser: User | null;
  isLoading: boolean;
  isEditing: boolean;
};

class AccountOverview extends React.Component<Props, State> {
  input: any = null;

  state: State = {
    account: null,
    companyName: '',
    companyLogoUrl: '',
    currentUser: null,
    isLoading: true,
    isEditing: false,
  };

  async componentDidMount() {
    // NB: this fetches the account data and also handles setting
    // this.state.account and this.state.companyName
    await this.fetchLatestAccountInfo();
    const currentUser = await API.me();

    this.setState({currentUser, isLoading: false});
  }

  fetchLatestAccountInfo = async () => {
    const account = await API.fetchAccountInfo();
    const {
      company_name: companyName,
      company_logo_url: companyLogoUrl,
    } = account;
    logger.debug('Account info:', account);

    this.setState({account, companyName, companyLogoUrl});
  };

  handleChangeCompanyName = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({companyName: e.target.value});
  };

  handleChangeCompanyLogoUrl = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({companyLogoUrl: e.target.value});
  };

  handleStartEditing = () => {
    this.setState({isEditing: true});
  };

  handleCancel = () => {
    return this.fetchLatestAccountInfo().then(() =>
      this.setState({isEditing: false})
    );
  };

  handleUpdate = async (updates: {
    company_name?: string;
    company_logo_url?: string;
    time_zone?: string;
    working_hours?: Array<WorkingHours>;
    settings?: Partial<AccountSettings>;
  }) => {
    return API.updateAccountInfo(updates)
      .then((account) => {
        logger.debug('Successfully updated account details!', account);

        this.setState({account, isEditing: false});
      })
      .catch((err) => {
        logger.error('Failed to update account details!', err);

        return this.fetchLatestAccountInfo();
      })
      .then(() => this.setState({isEditing: false}));
  };

  handleUpdateCompany = () => {
    const {companyName, companyLogoUrl} = this.state;

    return this.handleUpdate({
      company_name: companyName,
      company_logo_url: companyLogoUrl,
    });
  };

  render() {
    const {
      account,
      currentUser,
      companyName,
      companyLogoUrl,
      isLoading,
      isEditing,
    } = this.state;

    if (isLoading) {
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
    } else if (!account || !currentUser) {
      return null;
    }

    const {
      id: token,
      time_zone: timezone,
      working_hours: workingHours = [],
    } = account;
    const settings = account.settings || {};

    return (
      <Container sx={{maxWidth: 640}}>
        <Box mb={4}>
          <Title level={3}>Account Overview</Title>

          <Paragraph>
            <Text>This is your account token: </Text>
            <Text strong keyboard copyable>
              {token}
            </Text>
          </Paragraph>

          <Box mb={3} sx={{maxWidth: 480}}>
            <label htmlFor="company_name">Company name:</label>
            <Input
              id="company_name"
              type="text"
              value={companyName}
              onChange={this.handleChangeCompanyName}
              disabled={!isEditing}
            />
          </Box>

          <Flex sx={{alignItems: 'center'}}>
            <Box mb={3} mr={3} sx={{maxWidth: 480, flex: 1}}>
              <label htmlFor="company_logo_url">Company logo URL:</label>
              <Input
                id="company_logo_url"
                type="text"
                value={companyLogoUrl}
                onChange={this.handleChangeCompanyLogoUrl}
                disabled={!isEditing}
              />
            </Box>

            <Box
              style={{
                height: 40,
                width: 40,
                borderRadius: '50%',
                backgroundPosition: 'center',
                backgroundSize: 'cover',
                backgroundImage: `url(${companyLogoUrl})`,
              }}
            />
          </Flex>

          {isEditing ? (
            <Flex>
              <Box mr={1}>
                <Button type="default" onClick={this.handleCancel}>
                  Cancel
                </Button>
              </Box>
              <Box>
                <Button type="primary" onClick={this.handleUpdateCompany}>
                  Save
                </Button>
              </Box>
            </Flex>
          ) : (
            <Button type="primary" onClick={this.handleStartEditing}>
              Edit
            </Button>
          )}
        </Box>

        <Divider />

        <Box mb={4}>
          <Title level={4}>Working hours</Title>

          <Paragraph>
            <Text type="secondary">
              Set your working hours so your users know when you're available to
              chat.
            </Text>
          </Paragraph>

          <WorkingHoursSelector
            timezone={timezone}
            workingHours={workingHours}
            onSave={this.handleUpdate}
          />
        </Box>

        <Divider />

        <Box mb={4} sx={{maxWidth: 480}}>
          <Title level={4}>Conversation reminders</Title>

          <Paragraph>
            <Text type="secondary">
              Configure reminder messages to nudge you when your team hasn't
              replied to an open conversation within the number of hours
              specified below.
            </Text>
          </Paragraph>

          <ConversationRemindersSettings
            settings={settings}
            onSave={this.handleUpdate}
          />
        </Box>
      </Container>
    );
  }
}

export default AccountOverview;
