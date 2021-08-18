import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {Button, Input, Text, Title} from '../common';
import {useAuth} from './AuthProvider';
import logger from '../../logger';

type Props = {
  query: string;
  onSubmit: (
    email: string,
    password: string,
    redirect: string
  ) => Promise<void>;
};
type State = {
  loading: boolean;
  email: string;
  password: string;
  error: any;
  redirect: string;
};

export class Login extends React.Component<Props, State> {
  state: State = {
    loading: false,
    email: '',
    password: '',
    error: null,
    redirect: '/conversations',
  };

  componentDidMount() {
    const {redirect = '/conversations'} = qs.parse(this.props.query);

    this.setState({redirect: String(redirect)});
  }

  handleChangeEmail = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({email: e.target.value});
  };

  handleChangePassword = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({password: e.target.value});
  };

  handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    this.setState({loading: true, error: null});
    const {email, password, redirect} = this.state;

    // TODO: handle login through API
    this.props.onSubmit(email, password, redirect).catch((err) => {
      logger.error('Error!', err);
      const error = err.response?.body?.error?.message || 'Invalid credentials';

      this.setState({error, loading: false});
    });
  };

  render() {
    const {query} = this.props;
    const {loading, email, password, error} = this.state;

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
              <Button
                block
                size="large"
                type="primary"
                htmlType="submit"
                loading={loading}
              >
                Log in
              </Button>
            </Box>

            {error && (
              <Box mt={2}>
                <Text type="danger">{error}</Text>
              </Box>
            )}

            <Box mt={error ? 3 : 4}>
              Don't have an account?{' '}
              <Link to={`/register${query}`}>Sign up!</Link>
            </Box>
            <Box my={3}>
              <Link to="/reset-password">Forgot your password?</Link>
            </Box>
          </form>
        </Box>
      </Flex>
    );
  }
}

const LoginPage = (props: RouteComponentProps) => {
  const auth = useAuth();

  const handleSubmit = async (
    email: string,
    password: string,
    redirect: string
  ) => {
    return auth
      .login({email, password})
      .then(() => props.history.push(redirect));
  };

  return <Login query={props.location.search} onSubmit={handleSubmit} />;
};

export default LoginPage;
