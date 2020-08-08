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
  companyName: string;
  email: string;
  password: string;
  passwordConfirmation: string;
  inviteToken?: string;
  error: any;
};

class Register extends React.Component<Props, State> {
  state: State = {
    loading: false,
    companyName: '',
    email: '',
    password: '',
    passwordConfirmation: '',
    inviteToken: '',
    error: null,
  };

  componentDidMount() {
    const {invite: inviteToken} = this.props.match.params;
    this.setState({inviteToken});
  }

  handleChangeCompanyName = (e: any) => {
    this.setState({companyName: e.target.value});
  };

  handleChangeEmail = (e: any) => {
    this.setState({email: e.target.value});
  };

  handleChangePassword = (e: any) => {
    let value = e.target.value;
    this.setState({password: value});
    this.validatePassword(value);
  };

  handleChangePasswordConfirmation = (e: any) => {
    let value = e.target.value;
    this.setState({passwordConfirmation: value});
    this.validatePasswordConfirmation(value);
  };

  validatePasswordConfirmation(passwordConfirmation: string) {
    if (passwordConfirmation !== this.state.password) {
      this.setState({error: 'password confirmation does not match'});
    } else {
      this.setState({error: null});
    }
  }

  validatePassword(password: string) {
    // skip validation until password confirmation is set
    if (this.state.passwordConfirmation.length === 0) return;

    if (password !== this.state.passwordConfirmation) {
      this.setState({error: 'password confirmation does not match'});
    } else {
      this.setState({error: null});
    }
  }

  handleSubmit = (e: any) => {
    e.preventDefault();

    this.setState({loading: true, error: null});
    const {
      companyName,
      inviteToken,
      email,
      password,
      passwordConfirmation,
    } = this.state;

    this.props
      .onSubmit({
        companyName,
        inviteToken,
        email,
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
    const {
      loading,
      inviteToken,
      companyName,
      email,
      password,
      passwordConfirmation,
      error,
    } = this.state;

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
          <Title level={1}>Get started</Title>

          <form onSubmit={this.handleSubmit}>
            {!inviteToken && (
              <Box mb={2}>
                <label htmlFor="companyName">Company Name</label>
                <Input
                  id="companyName"
                  size="large"
                  type="companyName"
                  autoComplete="company-name"
                  value={companyName}
                  onChange={this.handleChangeCompanyName}
                />
              </Box>
            )}

            <Box mb={2}>
              <label htmlFor="email">Email</label>
              <Input
                id="email"
                size="large"
                type="email"
                autoComplete="username"
                value={email}
                onChange={this.handleChangeEmail}
              />
            </Box>

            <Box mb={2}>
              <label htmlFor="password">Password</label>
              <Input
                id="password"
                size="large"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={this.handleChangePassword}
              />
            </Box>

            <Box mb={2}>
              <label htmlFor="confirm_password">Confirm password</label>
              <Input
                id="confirm_password"
                size="large"
                type="password"
                autoComplete="current-password"
                value={passwordConfirmation}
                onChange={this.handleChangePasswordConfirmation}
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
                Register
              </Button>
            </Box>

            {error && (
              <Box mt={2}>
                <Text type="danger">{error}</Text>
              </Box>
            )}

            <Box mt={error ? 3 : 4}>
              Already have an account? <Link to="login">Log in!</Link>
            </Box>
          </form>
        </Box>
      </Flex>
    );
  }
}

const RegisterPage = (props: RouteComponentProps) => {
  const auth = useAuth();

  return <Register {...props} onSubmit={auth.register} />;
};

export default RegisterPage;
