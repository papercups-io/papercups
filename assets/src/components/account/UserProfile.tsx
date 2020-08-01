import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Input, Paragraph, Title} from '../common';
import * as API from '../../api';

type Props = {};
type State = {
  fullName: string;
  displayName: string;
  profilePhotoUrl: string;
  isLoading: boolean;
  isEditing: boolean;
};

class UserProfile extends React.Component<Props, State> {
  input: any = null;

  state: State = {
    fullName: '',
    displayName: '',
    profilePhotoUrl: '',
    isLoading: true,
    isEditing: false,
  };

  async componentDidMount() {
    await this.fetchLatestProfile();

    this.setState({isLoading: false});
  }

  fetchLatestProfile = async () => {
    const profile = await API.fetchUserProfile();

    if (profile) {
      const {
        display_name: displayName,
        full_name: fullName,
        profile_photo_url: profilePhotoUrl,
      } = profile;

      this.setState({
        displayName,
        fullName,
        profilePhotoUrl,
      });
    } else {
      this.setState({
        displayName: '',
        fullName: '',
        profilePhotoUrl: '',
      });
    }
  };

  handleChangeFullName = (e: any) => {
    this.setState({fullName: e.target.value});
  };

  handleChangeDisplayName = (e: any) => {
    this.setState({displayName: e.target.value});
  };

  handleChangeProfilePhotoUrl = (e: any) => {
    this.setState({profilePhotoUrl: e.target.value});
  };

  handleCancel = () => {
    return this.fetchLatestProfile().then(() =>
      this.setState({isEditing: false})
    );
  };

  handleUpdate = () => {
    const {displayName, fullName, profilePhotoUrl} = this.state;

    return API.updateUserProfile({
      display_name: displayName,
      full_name: fullName,
      profile_photo_url: profilePhotoUrl,
    })
      .then((profile) => {
        console.log('Successfully updated profile!', profile);

        this.setState({isEditing: false});
      })
      .catch((err) => {
        console.log('Failed to update profile!', err);

        return this.fetchLatestProfile();
      })
      .then(() => this.setState({isEditing: false}));
  };

  handleStartEditing = () => {
    this.setState({isEditing: true});
  };

  render() {
    const {
      isLoading,
      fullName,
      displayName,
      profilePhotoUrl,
      isEditing,
    } = this.state;

    if (isLoading) {
      return null; // TODO: switch to loading state
    }

    return (
      <Box p={4}>
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
            disabled={!isEditing}
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
      </Box>
    );
  }
}

export default UserProfile;
