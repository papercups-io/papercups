import React, {useState, useEffect, useContext} from 'react';
import {getAuthTokens, setAuthTokens, removeAuthTokens} from '../storage';
import * as API from '../api';

const defaultRedirectCallback = () =>
  window.history.replaceState({}, document.title, window.location.pathname);

export const AuthContext = React.createContext<{
  isAuthenticated: boolean;
  tokens: any | null;
  loading: boolean;
  register: (params: any) => Promise<void>;
  login: (params: any) => Promise<void>;
  logout: () => Promise<void>;
}>({
  isAuthenticated: false,
  tokens: null,
  loading: false,
  register: () => Promise.resolve(),
  login: () => Promise.resolve(),
  logout: () => Promise.resolve(),
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({
  children,
  onRedirectCallback = defaultRedirectCallback,
}: React.PropsWithChildren<{
  onRedirectCallback?: (state: any) => void;
}>) => {
  const t = getAuthTokens();
  // TODO: experiment with `useReducer` for managing auth state
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [tokens, setTokens] = useState(t);
  const [loading, setLoading] = useState(true);
  // const [error, setError] = useState(null);

  const handleAuthSuccess = (tokens: any) => {
    setAuthTokens(tokens);
    setTokens(tokens);
    setIsAuthenticated(true);
  };

  const handleClearAuth = () => {
    removeAuthTokens();
    setTokens(null);
    setIsAuthenticated(false);
  };

  useEffect(() => {
    console.log('AuthProvider mounted!');
    const renewToken = tokens && tokens.renew_token;

    if (!renewToken) {
      setLoading(false);

      return;
    }

    // Check if user is logged in already
    API.renew(renewToken)
      .then((tokens) => handleAuthSuccess(tokens))
      .catch((err) => console.log('Error renewing session!', err))
      .then(() => setLoading(false));
    // eslint-disable-next-line
  }, []);

  const register = async (params: API.RegisterParams): Promise<void> => {
    console.log('Signing up!');
    // Set user, authenticated status, etc
    return API.register(params)
      .then((tokens) => handleAuthSuccess(tokens))
      .then(() => {
        console.log('Successfully signed up!');
      });
  };

  const login = async (params: API.LoginParams): Promise<void> => {
    console.log('Logging in!');
    // Set user, authenticated status, etc
    return API.login(params)
      .then((tokens) => handleAuthSuccess(tokens))
      .then(() => {
        console.log('Successfully logged in!');
      });
  };

  const logout = async (): Promise<void> => {
    console.log('Logging out!');
    // Set user, authenticated status, etc
    return API.logout()
      .then(() => handleClearAuth())
      .then(() => {
        console.log('Successfully logged out!');
      });
  };

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        tokens,
        loading,
        register,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
