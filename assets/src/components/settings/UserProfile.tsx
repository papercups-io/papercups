import React from 'react';
import {RouteComponentProps} from 'react-router';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {
  colors,
  notification,
  Button,
  Container,
  Checkbox,
  Divider,
  Input,
  Paragraph,
  Text,
  Title,
} from '../common';
import * as API from '../../api';
import logger from '../../logger';
import {PersonalGmailAuthorizationButton} from '../integrations/GoogleAuthorizationButton';

type Props = RouteComponentProps<{}> & {};
type State = {
  email: string;
  fullName: string;
  displayName: string;
  profilePhotoUrl: string;
  shouldEmailOnNewMessages: boolean;
  shouldEmailOnNewConversations: boolean;
  personalGmailAuthorization: any | null;
  isLoading: boolean;
  isEditing: boolean;
};

class UserProfile extends React.Component<Props, State> {
  input: any = null;

  state: State = {
    email: '',
    fullName: '',
    displayName: '',
    profilePhotoUrl: '',
    shouldEmailOnNewMessages: false,
    shouldEmailOnNewConversations: false,
    personalGmailAuthorization: null,
    isLoading: true,
    isEditing: false,
  };

  async componentDidMount() {
    const {location, history} = this.props;
    const {search} = location;
    const q = qs.parse(search);
    const code = q.code ? String(q.code) : null;

    if (code) {
      const success = await this.authorizeGoogleIntegration(code, q);

      if (success) {
        history.push('/settings/profile');
      }
    }

    await this.fetchLatestProfile();
    await this.fetchLatestSettings();
    // await this.fetchGmailAuthorization();

    this.setState({isLoading: false});
  }

  authorizeGoogleIntegration = async (code: string, query: any) => {
    const scope = query.scope ? String(query.scope) : null;
    const state = query.state ? String(query.state) : null;

    return API.authorizeGoogleIntegration({code, scope, state})
      .then((result) => {
        logger.debug('Successfully authorized Google:', result);

        return true;
      })
      .catch((err) => {
        logger.error('Failed to authorize Google:', err);

        const description =
          err?.response?.body?.error?.message || err?.message || String(err);

        notification.error({
          message: 'Failed to authorize Google',
          duration: null,
          description,
        });

        return false;
      });
  };

  fetchLatestProfile = async () => {
    const profile = await API.fetchUserProfile();

    if (profile) {
      logger.debug('Profile:', profile);
      const {
        email,
        display_name: displayName,
        full_name: fullName,
        profile_photo_url: profilePhotoUrl,
      } = profile;

      this.setState({
        email,
        displayName,
        fullName,
        profilePhotoUrl,
      });
    } else {
      // NB: this also handles resetting these values if the optimistic update fails
      this.setState({
        email: '',
        displayName: '',
        fullName: '',
        profilePhotoUrl: '',
      });
    }
  };

  fetchLatestSettings = async () => {
    const settings = await API.fetchUserSettings();

    if (settings) {
      this.setState({
        shouldEmailOnNewMessages: settings.email_alert_on_new_message,
        shouldEmailOnNewConversations: settings.email_alert_on_new_conversation,
      });
    } else {
      // NB: this also handles resetting these values if the optimistic update fails
      this.setState({
        shouldEmailOnNewMessages: false,
        shouldEmailOnNewConversations: false,
      });
    }
  };

  fetchGmailAuthorization = async () => {
    const authorization = await API.fetchGoogleAuthorization({
      client: 'gmail',
      type: 'personal',
    });

    this.setState({
      personalGmailAuthorization: authorization,
    });
  };

  handleDisconnectGmail = async (authorizationId: string) => {
    return API.deleteGoogleAuthorization(authorizationId)
      .then(() => this.fetchGmailAuthorization())
      .catch((err) =>
        logger.error('Failed to remove Gmail authorization:', err)
      );
  };

  handleChangeFullName = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({fullName: e.target.value});
  };

  handleChangeDisplayName = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({displayName: e.target.value});
  };

  handleChangeProfilePhotoUrl = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({profilePhotoUrl: e.target.value});
  };

  handleCancel = async () => {
    return this.fetchLatestProfile().then(() =>
      this.setState({isEditing: false})
    );
  };

  handleUpdate = async () => {
    const {displayName, fullName, profilePhotoUrl} = this.state;

    return API.updateUserProfile({
      display_name: displayName,
      full_name: fullName,
      profile_photo_url: profilePhotoUrl,
    })
      .then((profile) => {
        logger.debug('Successfully updated profile!', profile);

        this.setState({isEditing: false});
      })
      .catch((err) => {
        logger.error('Failed to update profile!', err);

        return this.fetchLatestProfile();
      })
      .then(() => this.setState({isEditing: false}));
  };

  handleEmailAlertOnNewMessage = async (e: any) => {
    const shouldEmailOnNewMessages = e.target.checked;

    // Optimistic update
    this.setState({shouldEmailOnNewMessages});

    return API.updateUserSettings({
      email_alert_on_new_message: shouldEmailOnNewMessages,
    }).catch((err) => {
      logger.error('Failed to update settings!', err);
      // Reset if fails to actually update
      return this.fetchLatestSettings();
    });
  };

  handleEmailAlertOnNewConversation = async (e: any) => {
    const shouldEmailOnNewConversations = e.target.checked;

    // Optimistic update
    this.setState({shouldEmailOnNewConversations});

    return API.updateUserSettings({
      email_alert_on_new_conversation: shouldEmailOnNewConversations,
    }).catch((err) => {
      logger.error('Failed to update settings!', err);
      // Reset if fails to actually update
      return this.fetchLatestSettings();
    });
  };

  handleStartEditing = () => {
    this.setState({isEditing: true});
  };

  render() {
    const {
      isLoading,
      email,
      fullName,
      displayName,
      profilePhotoUrl,
      personalGmailAuthorization,
      shouldEmailOnNewMessages,
      shouldEmailOnNewConversations,
      isEditing,
    } = this.state;

    if (isLoading) {
      return null; // TODO: switch to loading state
    }

    const gmailAuthorizationId = personalGmailAuthorization?.id;
    const hasGmailConnection = !!gmailAuthorizationId;

    return (
      <Container sx={{maxWidth: 640}}>
        <Title level={3}>My Profile</Title>

        <Box mb={3} sx={{maxWidth: 480}}>
          <Paragraph>
            This information will affect how you appear in the chat. Your
            display name will be prioritized first, but if no display name is
            provided, your full name or email will be used instead.
          </Paragraph>
        </Box>

        <Box mb={3} sx={{maxWidth: 480}}>
          <label htmlFor="full_name">Full name:</label>
          <Input
            id="full_name"
            type="text"
            value={fullName}
            onChange={this.handleChangeFullName}
            placeholder="What's your name?"
            disabled={!isEditing}
          />
        </Box>

        <Box mb={3} sx={{maxWidth: 480}}>
          <label htmlFor="display_name">Display name:</label>
          <Input
            id="display_name"
            type="text"
            value={displayName}
            onChange={this.handleChangeDisplayName}
            placeholder="How would you like your name to be displayed?"
            disabled={!isEditing}
          />
        </Box>

        <Box mb={3} sx={{maxWidth: 480}}>
          <label htmlFor="email">Email:</label>
          <Input
            style={{color: colors.text}}
            id="email"
            type="text"
            value={email}
            disabled
          />
        </Box>

        <Flex sx={{alignItems: 'center'}}>
          <Box mb={3} mr={3} sx={{maxWidth: 480, flex: 1}}>
            <label htmlFor="profile_photo_url">Profile image URL:</label>
            <Input
              id="profile_photo_url"
              type="text"
              value={profilePhotoUrl}
              onChange={this.handleChangeProfilePhotoUrl}
              placeholder="Enter an image URL for your profile photo"
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
              backgroundImage: `url(${profilePhotoUrl})`,
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

        <Divider />

        <Title level={3}>Notification Settings</Title>

        <Box mb={3} sx={{maxWidth: 480}}>
          <Paragraph>
            Choose how you would like to be alerted when your account receives
            new messages from customers.
          </Paragraph>
        </Box>

        <Box mb={3}>
          <Checkbox
            checked={shouldEmailOnNewConversations}
            onChange={this.handleEmailAlertOnNewConversation}
          >
            <Text>
              Send email alert on <Text strong>new conversations</Text> (initial
              message only)
            </Text>
          </Checkbox>
        </Box>

        <Box mb={3}>
          <Checkbox
            checked={shouldEmailOnNewMessages}
            onChange={this.handleEmailAlertOnNewMessage}
          >
            <Text>
              Send email alert on <Text strong>all new messages</Text>
            </Text>
          </Checkbox>
        </Box>

        {/* TODO: figure out how to handle personal Gmail accounts better */}
        {false && (
          <Box>
            <Divider />

            <Title level={3}>Link Gmail Account</Title>

            <Box mb={3} sx={{maxWidth: 480}}>
              <Paragraph>
                By linking your Gmail account, you can send emails directly from
                Papercups.
              </Paragraph>
            </Box>

            <Box mb={3}>
              <PersonalGmailAuthorizationButton
                isConnected={hasGmailConnection}
                authorizationId={gmailAuthorizationId}
                onDisconnectGmail={this.handleDisconnectGmail}
              />
            </Box>
          </Box>
        )}
      </Container>
    );
  }
}

export default UserProfile;
