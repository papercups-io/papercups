import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  notification,
  Button,
  Divider,
  Input,
  Paragraph,
  Text,
  Title,
} from '../common';
import Spinner from '../Spinner';
import AccountUsersTable from './AccountUsersTable';
import DisabledUsersTable from './DisabledUsersTable';
import WorkingHoursSelector from './WorkingHoursSelector';
import {WorkingHours} from './support';
import * as API from '../../api';
import {Account, User} from '../../types';
import {FRONTEND_BASE_URL} from '../../config';
import {sleep, hasValidStripeKey} from '../../utils';
import logger from '../../logger';

type Props = {};
type State = {
  account: Account | null;
  companyName: string;
  currentUser: User | null;
  inviteUrl: string;
  isLoading: boolean;
  isEditing: boolean;
  isRefreshing: boolean;
};

class AccountOverview extends React.Component<Props, State> {
  input: any = null;

  state: State = {
    account: null,
    companyName: '',
    currentUser: null,
    inviteUrl: '',
    isLoading: true,
    isEditing: false,
    isRefreshing: false,
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
    const {company_name: companyName} = account;
    logger.debug('Account info:', account);

    this.setState({account, companyName});
  };

  hasAdminRole = () => {
    const {currentUser} = this.state;

    return !!currentUser && currentUser.role === 'admin';
  };

  handleGenerateInviteUrl = async () => {
    try {
      const {id: token} = await API.generateUserInvitation();

      this.setState(
        {
          inviteUrl: `${FRONTEND_BASE_URL}/register/${token}`,
        },
        () => this.focusAndHighlightInput()
      );
    } catch (err) {
      const hasServerErrorMessage = !!err?.response?.body?.error?.message;
      const shouldDisplayBillingLink =
        hasServerErrorMessage && hasValidStripeKey();
      const description =
        err?.response?.body?.error?.message || err?.message || String(err);

      notification.error({
        message: hasServerErrorMessage
          ? 'Please upgrade to add more users!'
          : 'Failed to generate user invitation!',
        description,
        duration: 10, // 10 seconds
        btn: (
          <a
            href={
              shouldDisplayBillingLink
                ? '/billing'
                : 'https://papercups.io/pricing'
            }
          >
            <Button type="primary" size="small">
              Upgrade subscription
            </Button>
          </a>
        ),
      });
    }
  };

  focusAndHighlightInput = () => {
    if (!this.input) {
      return;
    }

    this.input.focus();
    this.input.select();

    if (document.queryCommandSupported('copy')) {
      document.execCommand('copy');
      notification.open({
        message: 'Copied to clipboard!',
        description:
          'You can now paste your unique invitation URL to a teammate.',
      });
    }
  };

  handleChangeCompanyName = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({companyName: e.target.value});
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
    time_zone?: string;
    working_hours?: Array<WorkingHours>;
  }) => {
    return API.updateAccountInfo(updates)
      .then((account) => {
        logger.debug('Successfully updated company name!', account);

        this.setState({account, isEditing: false});
      })
      .catch((err) => {
        logger.error('Failed to update company name!', err);

        return this.fetchLatestAccountInfo();
      })
      .then(() => this.setState({isEditing: false}));
  };

  handleUpdateCompanyName = () => {
    const {companyName} = this.state;

    return this.handleUpdate({company_name: companyName});
  };

  handleDisableUser = async (user: User) => {
    this.setState({isRefreshing: true});
    const {id: userId} = user;

    return API.disableAccountUser(userId)
      .then((user) => {
        notification.success({
          message: 'Successfully disabled user!',
          description: `If this was a mistake, you can renable ${user.email} below.`,
        });
      })
      .then(() => sleep(400)) // Add slight delay so not too jarring
      .then(() => this.fetchLatestAccountInfo())
      .catch((err) => {
        const description =
          err?.response?.body?.error?.message ||
          err?.message ||
          'Something went wrong. Please contact us or try again in a few minutes.';
        notification.error({
          message: 'Failed to disable user!',
          description,
        });
      })
      .then(() => this.setState({isRefreshing: false}));
  };

  handleEnableUser = async (user: User) => {
    this.setState({isRefreshing: true});
    const {id: userId} = user;

    return API.enableAccountUser(userId)
      .then((user) => {
        notification.success({
          message: 'Successfully re-enabled user!',
          description: `If this was a mistake, you can disable ${user.email} above.`,
        });
      })
      .then(() => sleep(400)) // Add slight delay so not too jarring
      .then(() => this.fetchLatestAccountInfo())
      .catch((err) => {
        const description =
          err?.response?.body?.error?.message ||
          err?.message ||
          'Something went wrong. Please contact us or try again in a few minutes.';
        notification.error({
          message: 'Failed to enable user!',
          description,
        });
      })
      .then(() => this.setState({isRefreshing: false}));
  };

  render() {
    const {
      account,
      currentUser,
      companyName,
      inviteUrl,
      isLoading,
      isEditing,
      isRefreshing,
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
      users = [],
      working_hours: workingHours = [],
    } = account;
    const isAdmin = this.hasAdminRole();

    return (
      <Box p={4}>
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

          {isEditing ? (
            <Flex>
              <Box mr={1}>
                <Button type="default" onClick={this.handleCancel}>
                  Cancel
                </Button>
              </Box>
              <Box>
                <Button type="primary" onClick={this.handleUpdateCompanyName}>
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
            <Text>
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

        {isAdmin && (
          <>
            <Box mb={4}>
              <Title level={4}>Invite new teammate</Title>

              <Paragraph>
                <Text>
                  Generate a unique invitation URL below and send it to your
                  teammate.
                </Text>
              </Paragraph>

              <Flex sx={{maxWidth: 640}}>
                <Box sx={{flex: 1}} mr={1}>
                  <Input
                    ref={(el) => (this.input = el)}
                    type="text"
                    placeholder="Click the button to generate an invite URL"
                    value={inviteUrl}
                  ></Input>
                </Box>
                <Box>
                  <Button type="primary" onClick={this.handleGenerateInviteUrl}>
                    Generate invite URL
                  </Button>
                </Box>
              </Flex>
            </Box>
            <Divider />
          </>
        )}

        <Box mb={4}>
          <Title level={4}>Team</Title>
          <AccountUsersTable
            loading={isRefreshing}
            users={users.filter((u: User) => !u.disabled_at)}
            currentUser={currentUser}
            isAdmin={isAdmin}
            onDisableUser={this.handleDisableUser}
          />
        </Box>

        {isAdmin && (
          <Box mb={4}>
            <Title level={4}>Disabled users</Title>
            <DisabledUsersTable
              loading={isRefreshing}
              users={users.filter((u: User) => !!u.disabled_at)}
              isAdmin={isAdmin}
              onEnableUser={this.handleEnableUser}
            />
          </Box>
        )}
      </Box>
    );
  }
}

export default AccountOverview;
