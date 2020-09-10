import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Input, Text, Title} from '../common';
import {useAuth} from './AuthProvider';

type Props = RouteComponentProps<{invite?: string}> & {
  onSubmit: (params: any) => Promise<void>;
};

type State = {
  loading: boolean;
  submitted: boolean;
  password: string;
  passwordConfirmation: string;
  error: any;
};

class PasswordReset extends React.Component<Props, State> {
  state: State = {
    loading: false,
    submitted: false,
    password: '',
    passwordConfirmation: '',
    error: null,
  };

  componentDidMount() {
    // load token?
  }

  handleChangePassword = (e: any) => {
    this.setState({password: e.target.value});
  };

  handleChangePasswordConfirmation = (e: any) => {
    this.setState({passwordConfirmation: e.target.value});
  };

  getValidationError = () => {
    const {password, passwordConfirmation} = this.state;

    if (!password) {
      return 'Password is required';
    } else if (password !== passwordConfirmation) {
      return 'Password confirmation does not match';
    } else {
      return null;
    }
  };

  handleInputBlur = () => {
    if (!this.state.submitted) {
      return;
    }

    this.setState({error: this.getValidationError()});
  };

  handleSubmit = (e: any) => {
    e.preventDefault();

    const error = this.getValidationError();

    if (error) {
      this.setState({error, submitted: true});

      return;
    }

    this.setState({loading: true, submitted: true, error: null});
    const {password, passwordConfirmation} = this.state;

    this.props
      .onSubmit({
        password,
        passwordConfirmation,
      })
      .then(() => this.props.history.push('/conversations'))
      .catch((err) => {
        console.log('Error!', err);
        // TODO: provide more granular error messages?
        const error =
          err.response?.body?.error?.message || 'Invalid credentials';

        this.setState({error, loading: false});
      });
  };

  render() {
    const {loading, password, passwordConfirmation, error} = this.state;

    return (
      <Flex
        px={[2, 5]}
        py={5}
        sx={{
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <Box sx={{width: '100%', maxWidth: 320}}>
          <Title level={1}>Reset password</Title>

          <form onSubmit={this.handleSubmit}>
            <Box mb={2}>
              <label htmlFor="password">New password</label>
              <Input
                id="password"
                size="large"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={this.handleChangePassword}
                onBlur={this.handleInputBlur}
              />
            </Box>

            <Box mb={2}>
              <label htmlFor="confirm_password">Confirm new password</label>
              <Input
                id="confirm_password"
                size="large"
                type="password"
                autoComplete="current-password"
                value={passwordConfirmation}
                onChange={this.handleChangePasswordConfirmation}
                onBlur={this.handleInputBlur}
              />
            </Box>

            <Box mt={3}>
              <Button
                block
                size="large"
                type="primary"
                htmlType="submit"
                loading={loading}
              >
                Reset
              </Button>
            </Box>

            {error && (
              <Box mt={2}>
                <Text type="danger">{error}</Text>
              </Box>
            )}
          </form>
        </Box>
      </Flex>
    );
  }
}

const PasswordResetPage = (props: RouteComponentProps) => {
  // const auth = useAuth();

  return <PasswordReset {...props} onSubmit={() => Promise.resolve()} />;
};

export default PasswordResetPage;
