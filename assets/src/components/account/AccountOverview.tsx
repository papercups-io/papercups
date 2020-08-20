import React from 'react';
import {Box, Flex} from 'theme-ui';
import dayjs from 'dayjs';
import {
  colors,
  notification,
  Button,
  Input,
  Paragraph,
  Table,
  Text,
  Title,
} from '../common';
import {SmileTwoTone} from '../icons';
import * as API from '../../api';
import {BASE_URL} from '../../config';

type Props = {};
type State = {
  account: any;
  companyName: string;
  currentUser: any;
  inviteUrl: string;
  isEditing: boolean;
};

class AccountOverview extends React.Component<Props, State> {
  input: any = null;

  state: State = {
    account: null,
    companyName: '',
    currentUser: null,
    inviteUrl: '',
    isEditing: false,
  };

  async componentDidMount() {
    // NB: this fetches the account data and also handles setting this.state.account and this.state.companyName
    await this.fetchLatestAccountInfo();

    const currentUser = await API.me();
    this.setState({currentUser});
  }

  fetchLatestAccountInfo = async () => {
    const account = await API.fetchAccountInfo();
    const {company_name: companyName} = account;

    this.setState({account, companyName});
  };

  handleGenerateInviteUrl = async () => {
    const {id: token} = await API.generateUserInvitation();

    this.setState(
      {
        inviteUrl: `${BASE_URL}/register/${token}`,
      },
      () => this.focusAndHighlightInput()
    );
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

  renderUsersTable = (users: Array<any>) => {
    const {currentUser} = this.state;
    const data = users.map((u) => {
      return {...u, key: u.id, name: '--'};
    });

    const columns = [
      {
        title: 'Email',
        dataIndex: 'email',
        key: 'email',
        render: (value: string, record: any) => {
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
    ];

    return <Table dataSource={data} columns={columns} />;
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
        console.log('Successfully updated company name!', account);

        this.setState({isEditing: false});
      })
      .catch((err) => {
        console.log('Failed to update company name!', err);

        return this.fetchLatestAccountInfo();
      })
      .then(() => this.setState({isEditing: false}));
  };

  render() {
    const {account, companyName, inviteUrl, isEditing} = this.state;

    if (!account) {
      return null;
    }

    const {id: token, users = []} = account;

    return (
      <Box p={4}>
        <Box mb={5}>
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

        <Box mb={5}>
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

        <Box mb={5}>
          <Title level={4}>Team</Title>
          {this.renderUsersTable(users)}
        </Box>
      </Box>
    );
  }
}

export default AccountOverview;
