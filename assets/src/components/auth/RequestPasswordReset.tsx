import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {Button, Input, Text, Title} from '../common';
import * as API from '../../api';
import logger from '../../logger';

type Props = RouteComponentProps & {
  onSubmit: (params: any) => Promise<void>;
};

type State = {
  loading: boolean;
  email: string;
  error: any;
};

class RequestPasswordReset extends React.Component<Props, State> {
  state: State = {
    loading: false,
    email: '',
    error: null,
  };

  componentDidMount() {
    //
  }

  handleChangeEmail = (e: any) => {
    this.setState({email: e.target.value});
  };

  handleSubmit = (e: any) => {
    e.preventDefault();

    this.setState({loading: true, error: null});
    const {email} = this.state;

    API.sendPasswordResetEmail(email)
      .then(({ok}) => {
        if (ok) {
          this.props.history.push('/reset-password-requested');
        } else {
          this.setState({
            error: 'Something went wrong! Try again in a few minutes.',
            loading: false,
          });
        }
      })
      .catch((err) => {
        logger.error('Error!', err);
        const error =
          err.response?.body?.error?.message ||
          'Something went wrong! Try again in a few minutes.';

        this.setState({error, loading: false});
      });
  };

  render() {
    const {loading, email, error} = this.state;

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

            <Box mt={3}>
              <Button
                block
                size="large"
                type="primary"
                htmlType="submit"
                loading={loading}
              >
                Submit
              </Button>
            </Box>

            {error && (
              <Box mt={2}>
                <Text type="danger">{error}</Text>
              </Box>
            )}

            <Box mt={error ? 3 : 4}>
              Back to <Link to="/login">login</Link>.
            </Box>
          </form>
        </Box>
      </Flex>
    );
  }
}

export default RequestPasswordReset;
