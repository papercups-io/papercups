import React, {useContext} from 'react';
import {getAuthTokens, setAuthTokens, removeAuthTokens} from '../../storage';
import * as API from '../../api';
import logger from '../../logger';
import {User} from '../../types';

export const AuthContext = React.createContext<{
  isAuthenticated: boolean;
  tokens: any | null;
  loading: boolean;
  currentUser: User | null;
  register: (params: any) => Promise<void>;
  login: (params: any) => Promise<void>;
  logout: () => Promise<void>;
  refresh: (token: string) => Promise<void>;
}>({
  isAuthenticated: false,
  tokens: null,
  loading: false,
  currentUser: null,
  register: () => Promise.resolve(),
  login: () => Promise.resolve(),
  logout: () => Promise.resolve(),
  refresh: () => Promise.resolve(),
});

export const useAuth = () => useContext(AuthContext);

// Refresh every 20 mins
const AUTH_SESSION_TTL = 20 * 60 * 1000;

type Props = React.PropsWithChildren<{}>;
type State = {
  loading: boolean;
  tokens: any;
  currentUser: User | null;
  isAuthenticated: boolean;
};

export class AuthProvider extends React.Component<Props, State> {
  timeout: any = null;

  constructor(props: Props) {
    super(props);

    const cachedTokens = getAuthTokens();

    this.state = {
      loading: true,
      isAuthenticated: false,
      currentUser: null,
      tokens: cachedTokens,
    };
  }

  async componentDidMount() {
    const {tokens} = this.state;
    const refreshToken = tokens && tokens.renew_token;

    if (!refreshToken) {
      this.setState({loading: false});

      return;
    }

    // Attempt refresh auth session on load
    await this.refresh(refreshToken);
    const currentUser = await this.fetchCurrentUser();

    this.setState({currentUser, loading: false});
  }

  componentWillUnmount() {
    clearTimeout(this.timeout);

    this.timeout = null;
  }

  handleAuthSuccess = async (tokens: any) => {
    setAuthTokens(tokens);

    const currentUser = await this.fetchCurrentUser();
    const nextRefreshToken = tokens && tokens.renew_token;

    this.setState({tokens, currentUser, isAuthenticated: true});

    // Refresh the session every 20 mins to avoid the access token expiring
    // (By default, the session will expire after 30 mins)
    this.timeout = setTimeout(
      () => this.refresh(nextRefreshToken),
      AUTH_SESSION_TTL
    );
  };

  handleClearAuth = () => {
    removeAuthTokens();

    this.setState({
      tokens: null,
      currentUser: null,
      isAuthenticated: false,
    });
  };

  fetchCurrentUser = async () => {
    return API.me()
      .then((user) => user)
      .catch((err) => {
        logger.error('Could not retrieve current user:', err);

        return null;
      });
  };

  refresh = async (refreshToken: string) => {
    return API.renew(refreshToken)
      .then((tokens) => this.handleAuthSuccess(tokens))
      .catch((err) => {
        logger.error('Invalid session:', err);
      });
  };

  register = async (params: API.RegisterParams): Promise<void> => {
    logger.debug('Signing up!');
    // Set user, authenticated status, etc
    return API.register(params)
      .then((tokens) => this.handleAuthSuccess(tokens))
      .then(() => {
        logger.debug('Successfully signed up!');
      });
  };

  login = async (params: API.LoginParams): Promise<void> => {
    logger.debug('Logging in!');
    // Set user, authenticated status, etc
    return API.login(params)
      .then((tokens) => this.handleAuthSuccess(tokens))
      .then(() => {
        logger.debug('Successfully logged in!');
      });
  };

  logout = async (): Promise<void> => {
    logger.debug('Logging out!');
    // Set user, authenticated status, etc
    return API.logout()
      .then(() => this.handleClearAuth())
      .then(() => {
        logger.debug('Successfully logged out!');
      });
  };

  render() {
    const {loading, isAuthenticated, tokens, currentUser} = this.state;

    return (
      <AuthContext.Provider
        value={{
          loading,
          isAuthenticated,
          tokens,
          currentUser,

          register: this.register,
          login: this.login,
          logout: this.logout,
          refresh: this.refresh,
        }}
      >
        {this.props.children}
      </AuthContext.Provider>
    );
  }
}
