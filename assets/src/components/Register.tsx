import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Input, Title} from './common';
import {useAuth} from './AuthProvider';

type Props = RouteComponentProps & {
  onSubmit: (params: any) => Promise<void>;
};
type State = {
  email: string;
  password: string;
  passwordConfirmation: string;
};

class Register extends React.Component<Props, State> {
  state: State = {email: '', password: '', passwordConfirmation: ''};

  componentDidMount() {
    //
  }

  handleChangeEmail = (e: any) => {
    this.setState({email: e.target.value});
  };

  handleChangePassword = (e: any) => {
    this.setState({password: e.target.value});
  };

  handleChangePasswordConfirmation = (e: any) => {
    this.setState({passwordConfirmation: e.target.value});
  };

  handleSubmit = (e: any) => {
    e.preventDefault();

    const {email, password, passwordConfirmation} = this.state;

    this.props
      .onSubmit({email, password, passwordConfirmation})
      .then(() => this.props.history.push('/conversations'))
      .catch((err) => console.log('Error!', err));
  };

  render() {
    const {email, password, passwordConfirmation} = this.state;

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
              <Button block size="large" type="primary" htmlType="submit">
                Register
              </Button>
            </Box>

            <Box mt={4}>
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
