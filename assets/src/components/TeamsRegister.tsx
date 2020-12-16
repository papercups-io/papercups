import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {Button, Input, Text, Title} from './common';
import logger from '../logger';
import * as msal from '@azure/msal-browser';

type Props = RouteComponentProps<{invite?: string}> & {
};
type State = {
};

// NAMING: the redirect-after-auth register'd to oauth screen
class Register extends React.Component<Props, State> {
  state: State = {
  };

  async componentDidMount() {
    const config = {
      auth: {
        clientId: '44ffc9f2-4c63-4bf6-92d6-b84d930c0a73',
        redirectUri: "http://localhost:3500/teams/register",
        // TODO: logout route that clears MS AD state from server: https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-spa-sign-in?tabs=javascript2#sign-out
        postLogoutRedirectUri: "http://localhost:3500/",
        authority: "https://login.microsoftonline.com/common",
      }
    }

    const userAgent = new msal.PublicClientApplication(config)

    const accessTokenRequest: any = {
      scopes: ["user.read"]
    }

    /*
    try {
      const accessTokenResponse = await userAgent.acquireTokenSilent(accessTokenRequest)
      let accessToken = accessTokenResponse.accessToken;
      console.log("GOT ACCESS TOKEN!")
      console.log(accessToken)
    }
    catch (error) {
      //Acquire token silent failure, and send an interactive request
      console.log(error);
      if (error instanceof msal.InteractionRequiredAuthError) {
      //if (error.errorMessage.indexOf("interaction_required") !== -1) {
        userAgent.acquireTokenRedirect(accessTokenRequest);
      }
    }
    */
  }

  render() {
    return (
      <Flex>
        <h2>Hello World from Teams</h2>
      </Flex>
    );
  }
}

const RegisterPage = (props: RouteComponentProps) => {
  return <Register {...props} />;
};

export default RegisterPage;
