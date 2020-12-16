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

class Register extends React.Component<Props, State> {
  state: State = {
  };

  async componentDidMount() {
    const config = {
      auth: {
        clientId: '44ffc9f2-4c63-4bf6-92d6-b84d930c0a73',
        redirectUri: "http://localhost:3500/teams",
        // TODO: logout route that clears MS AD state from server: https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-spa-sign-in?tabs=javascript2#sign-out
        postLogoutRedirectUri: "http://localhost:3500/",
        authority: "https://login.microsoftonline.com/common",
      },
      // caches the refresh token on user's browser
      // --> look at server-side token storage if we want to avoid this?
      cache: {
        cacheLocation: 'localStorage',
        storeAuthStateInCookie: true
      }
    }

    const loginRequest = {
      scopes: ["User.ReadWrite"]
    }

    async function acquireTokenOrRedirect(userAgent: any, signedInUser: any) {
      try {
        const accessTokenResponse = await userAgent.acquireTokenSilent({
          account: signedInUser,
          scopes: ["user.read"]
        })
        return accessTokenResponse
      }
      catch (error) {
        if (error.errorMessage.indexOf("interaction_required") !== -1) {
          console.log("redirecting to acquire token")
          await userAgent.acquireTokenRedirect({
            scopes: ["user.read"]
          });
        }
      }
    }

    function allowUserAccountSelection() {
      /*
      const currentAccounts = await userAgent.getAllAccounts();
      console.log("CURRENT ACCOUNTS")
      console.log(currentAccounts)

      if (currentAccounts === null) {
        // no accounts detected
      } else if (currentAccounts.length > 1) {
        //TODO: let user choose accts
        // Add choose account code here
        signedInUser = currentAccounts[0]
      } else if (currentAccounts.length === 1) {
        signedInUser = currentAccounts[0]
        let username = "";
        //username = currentAccounts[0].username;
      }
      */
    }

    console.log("MSAL")
    console.log(msal)
    const userAgent = new msal.PublicClientApplication(config);

    // attempt to get access code via redirect
    let signedInUser
    let accessToken
    try {
      // handles parsing code & token from query params
      const tokenResponse = await userAgent.handleRedirectPromise()
      console.log("TOKENRESPONSE")
      console.log(tokenResponse)

      if (tokenResponse) {
        signedInUser = tokenResponse.account;
      } else {
        signedInUser = await userAgent.getAllAccounts()[0]
      }
      console.log("retrieved user", signedInUser)

      // have user and token, attempt get token
      if (signedInUser && tokenResponse) {
        console.log("successful sign in!")
        console.log(signedInUser)
      } else if (signedInUser) {
        console.log("signed in, but no access tokens?")
        const accessTokenResponse = await acquireTokenOrRedirect(userAgent, signedInUser)
        console.log("ACCESS TOKEN RESPONSE")
        console.log(accessTokenResponse)
        accessToken = accessTokenResponse.accessToken
      } else {
        console.log("no sign-in, or tokenResponse - redirecting to SSO")
        await userAgent.loginRedirect({
          scopes: ["user.read"]
        });
      }
    }
    catch (error) {
      console.log("failed to handleRedirectPromise", error)
    }

    // attempt to use accessToken
    async function requestUserProfile(accessToken: any) {
      const headers = new Headers();
      const bearer = "Bearer " + accessToken;
      headers.append("Authorization", bearer);
      const url = "https://graph.microsoft.com/v1.0/me/joinedTeams";

      const res = await fetch(url, {
        method: "GET",
        headers: headers,
      })
      console.log("fetched profile!")
      console.log(res)
    }
    async function postChatMessage(accessToken: any) {
      const headers = new Headers();
      const bearer = "Bearer " + accessToken;
      headers.append("Authorization", bearer);
      const teamId = "8ae730af-1c24-4005-bd83-6326f9a38c62"
      const channelId = "19%3a4ffe109ef79944828b94064aa3069a64%40thread.tacv2"
      const url = `https://graph.microsoft.com/v1.0/teams/${teamId}/channels/${channelId}/messages`;

      const res = await fetch(url, {
        method: "POST",
        headers: headers,
        body: JSON.stringify({
          contentType: "html",
          content: "Posted via the Graph API!",
        })
      })
      console.log("fetched profile!")
      console.log(res)
    }
    //requestUserProfile(accessToken)
    postChatMessage(accessToken)
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
