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
};

class Login extends React.Component<Props, State> {
  state: State = {email: '', password: ''};

  componentDidMount() {
    //
  }

  handleChangeEmail = (e: any) => {
    this.setState({email: e.target.value});
  };

  handleChangePassword = (e: any) => {
    this.setState({password: e.target.value});
  };

  handleSubmit = (e: any) => {
    e.preventDefault();

    const {email, password} = this.state;

    // TODO: handle login through API
    this.props
      .onSubmit({email, password})
      .then(() => this.props.history.push('/conversations'))
      .catch((err) => console.log('Error!', err));
  };

  render() {
    const {email, password} = this.state;

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
          <Title level={1}>Welcome back</Title>

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

            <Box mt={3}>
              <Button block size="large" type="primary" htmlType="submit">
                Log in
              </Button>
            </Box>

            <Box mt={4}>
              Don't have an account? <Link to="register">Sign up!</Link>
            </Box>
          </form>
        </Box>
      </Flex>
    );
  }
}

const LoginPage = (props: RouteComponentProps) => {
  const auth = useAuth();

  return <Login {...props} onSubmit={auth.login} />;
};

export default LoginPage;
