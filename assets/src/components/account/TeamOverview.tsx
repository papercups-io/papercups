import React from 'react';
import {Box, Flex} from 'theme-ui';
import {
  notification,
  Button,
  Container,
  Divider,
  Input,
  Paragraph,
  Text,
  Title,
} from '../common';
import Spinner from '../Spinner';
import AccountUsersTable from './AccountUsersTable';
import DisabledUsersTable from './DisabledUsersTable';
import * as API from '../../api';
import {Account, User} from '../../types';
import {FRONTEND_BASE_URL, isUserInvitationEmailEnabled} from '../../config';
import {sleep, hasValidStripeKey} from '../../utils';
import logger from '../../logger';

type Props = {};
type State = {
  account: Account | null;
  currentUser: User | null;
  inviteUrl: string;
  inviteUserEmail: string;
  isLoading: boolean;
  isRefreshing: boolean;
  showInviteMoreInput: boolean;
};

class TeamOverview extends React.Component<Props, State> {
  input: Input | null = null;

  state: State = {
    account: null,
    currentUser: null,
    inviteUrl: '',
    inviteUserEmail: '',
    isLoading: true,
    isRefreshing: false,
    showInviteMoreInput: false,
  };

  async componentDidMount() {
    await this.fetchLatestAccountInfo();
    const currentUser = await API.me();

    this.setState({currentUser, isLoading: false});
  }

  fetchLatestAccountInfo = async () => {
    const account = await API.fetchAccountInfo();
    logger.debug('Account info:', account);
    this.setState({account});
  };

  hasAdminRole = () => {
    return this.state.currentUser?.role === 'admin';
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

  handleSendInviteEmail = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    try {
      const {inviteUserEmail} = this.state;
      await API.sendUserInvitationEmail(inviteUserEmail);
      notification.success({
        message: `Invitation was successfully sent to ${inviteUserEmail}!`,
        duration: 10, // 10 seconds
      });

      this.setState({inviteUserEmail: ''});
    } catch (err) {
      // TODO: consolidate error logic with handleGenerateInviteUrl
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

  handleChangeInviteUserEmail = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({inviteUserEmail: e.target.value});
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

  handleClickOnInviteMoreLink = () => {
    this.setState({showInviteMoreInput: true});
  };

  render() {
    const {
      account,
      currentUser,
      inviteUrl,
      inviteUserEmail,
      isLoading,
      isRefreshing,
      showInviteMoreInput,
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

    const {users = []} = account;
    const isAdmin = this.hasAdminRole();

    return (
      <Container>
        <Box mb={4}>
          <Title level={3}>My Team</Title>
        </Box>

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
                <Box mr={1}>
                  <Button type="primary" onClick={this.handleGenerateInviteUrl}>
                    Generate invite URL
                  </Button>
                </Box>
                <Box sx={{flex: 1}}>
                  <Input
                    ref={(el) => (this.input = el)}
                    type="text"
                    placeholder="Click the button to generate an invite URL"
                    disabled={!inviteUrl}
                    value={inviteUrl}
                  ></Input>
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

          {isAdmin && isUserInvitationEmailEnabled && (
            <Box mt={2}>
              {showInviteMoreInput ? (
                <form onSubmit={this.handleSendInviteEmail}>
                  <Flex sx={{maxWidth: 480}}>
                    <Box mr={1} sx={{flex: 1}}>
                      <Input
                        onChange={this.handleChangeInviteUserEmail}
                        placeholder="Email address"
                        required
                        type="email"
                        value={inviteUserEmail}
                      />
                    </Box>
                    <Button type="primary" htmlType="submit">
                      Send invite
                    </Button>
                  </Flex>
                </form>
              ) : (
                <Button
                  type="primary"
                  onClick={this.handleClickOnInviteMoreLink}
                >
                  Invite teammate
                </Button>
              )}
            </Box>
          )}
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
      </Container>
    );
  }
}

export default TeamOverview;
