import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import {
  colors,
  notification,
  Button,
  Divider,
  Input,
  Paragraph,
  Table,
  Tag,
  Text,
  Title,
} from '../common';
import Spinner from '../Spinner';
import {SmileTwoTone} from '../icons';
import * as API from '../../api';
import {User, Alignment} from '../../types';
import {BASE_URL} from '../../config';
import {sleep} from '../../utils';
import logger from '../../logger';

const AccountUsersTable = ({
  loading,
  users,
  currentUser,
  onDisableUser,
}: {
  loading?: boolean;
  users: Array<User>;
  currentUser: User;
  onDisableUser: (user: User) => void;
}) => {
  // TODO: how should we sort the users?
  const data = users.map((u) => {
    return {...u, key: u.id};
  });

  const columns = [
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (value: string, record: User) => {
        if (currentUser && record.id === currentUser.id) {
          return (
            <Flex sx={{alignItems: 'center'}}>
              <Text strong>{value}</Text>
              <SmileTwoTone
                style={{fontSize: 16, marginLeft: 4}}
                twoToneColor={colors.primary}
              />
            </Flex>
          );
        }

        return value;
      },
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string, record: User) => {
        const {full_name: fullName, display_name: displayName} = record;

        return fullName || displayName || '--';
      },
    },
    {
      title: 'Member since',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (value: string) => {
        const formatted = dayjs(value).format('MMMM DD, YYYY');

        return formatted;
      },
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      render: (value: string) => {
        switch (value) {
          case 'admin':
            return <Tag color={colors.green}>Admin</Tag>;
          case 'user':
            return <Tag>Member</Tag>;
          default:
            return '--';
        }
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      align: Alignment.Right,
      render: (value: string, record: User) => {
        // Current user cannot disable themselves
        if (currentUser && record.id === currentUser.id) {
          return null;
        }

        return (
          <Button danger onClick={() => onDisableUser(record)}>
            Disable
          </Button>
        );
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      pagination={false}
    />
  );
};

const DisabledUsersTable = ({
  loading,
  users,
  onEnableUser,
}: {
  loading?: boolean;
  users: Array<User>;
  onEnableUser: (user: User) => void;
}) => {
  // TODO: how should we sort the users?
  const data = users.map((u) => {
    return {...u, key: u.id};
  });

  const columns = [
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (value: string, record: User) => {
        return value;
      },
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (value: string, record: User) => {
        const {full_name: fullName, display_name: displayName} = record;

        return fullName || displayName || '--';
      },
    },
    {
      title: 'Member since',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (value: string) => {
        const formatted = dayjs(value).format('MMMM DD, YYYY');

        return formatted;
      },
    },
    {
      title: 'Disabled on',
      dataIndex: 'disabled_at',
      key: 'disabled_at',
      render: (value: string) => {
        const formatted = dayjs(value).format('MMMM DD, YYYY');

        return formatted;
      },
    },
    {
      title: '',
      dataIndex: 'action',
      key: 'action',
      align: Alignment.Right,
      render: (value: string, record: User) => {
        return <Button onClick={() => onEnableUser(record)}>Enable</Button>;
      },
    },
  ];

  return (
    <Table
      loading={loading}
      dataSource={data}
      columns={columns}
      pagination={false}
    />
  );
};

type Props = {};
type State = {
  account: any;
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
          inviteUrl: `${BASE_URL}/register/${token}`,
        },
        () => this.focusAndHighlightInput()
      );
    } catch (err) {
      logger.error('Failed to generate user invitation URL:', err);
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

  handleChangeCompanyName = (e: any) => {
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

  handleUpdate = () => {
    const {companyName} = this.state;

    return API.updateAccountInfo({company_name: companyName})
      .then((account) => {
        logger.debug('Successfully updated company name!', account);

        this.setState({isEditing: false});
      })
      .catch((err) => {
        logger.error('Failed to update company name!', err);

        return this.fetchLatestAccountInfo();
      })
      .then(() => this.setState({isEditing: false}));
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

    const {id: token, users = []} = account;

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
                <Button type="primary" onClick={this.handleUpdate}>
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

        {this.hasAdminRole() && (
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
                    placeholder="Click the button to generate an invite URL!"
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
            onDisableUser={this.handleDisableUser}
          />
        </Box>

        <Box mb={4}>
          <Title level={4}>Disabled users</Title>
          <DisabledUsersTable
            loading={isRefreshing}
            users={users.filter((u: User) => !!u.disabled_at)}
            onEnableUser={this.handleEnableUser}
          />
        </Box>
      </Box>
    );
  }
}

export default AccountOverview;
