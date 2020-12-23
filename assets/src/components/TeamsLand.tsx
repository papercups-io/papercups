import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Flex} from 'theme-ui';
//import qs from 'query-string';
//import logger from '../logger';
import * as msal from '@azure/msal-browser';

type Props = RouteComponentProps<{invite?: string}> & {
};
type State = {
};

const TEAM_ID_PAPERCUPS_TEST = "8ae730af-1c24-4005-bd83-6326f9a38c62"
const DESIRED_SCOPES = [
  "User.Read",
  "Team.ReadBasic.All",  // list joined Teams
]

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

    async function acquireTokenOrRedirect(userAgent: any, signedInUser: any) {
      try {
        const accessTokenResponse = await userAgent.acquireTokenSilent({
          account: signedInUser,
          scopes: DESIRED_SCOPES,
        })
        return accessTokenResponse
      }
      catch (error) {
        if (error.errorMessage.indexOf("interaction_required") !== -1) {
          console.log("redirecting to acquire token")
          await userAgent.acquireTokenRedirect({
            scopes: DESIRED_SCOPES,
          });
        }
      }
    }

    function allowUserAccountSelection() {
      // on Oauth, if a user has multiple Microsoft accounts, allow the user to select an account
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
          scopes: DESIRED_SCOPES,
        });
      }
    }
    catch (error) {
      console.log("failed to handleRedirectPromise", error)
    }

    // attempt to use accessToken
    function graphHeaders(accessToken: any) {
      const headers: Headers = new Headers();
      const bearer = "Bearer " + accessToken;
      headers.append("Authorization", bearer);
      headers.append("Content-Type", "application/json")
      return headers
    }
    async function getUserProfile(accessToken: any) {
      const url = "https://graph.microsoft.com/v1.0/me";

      const res = await fetch(url, {
        method: "GET",
        headers: graphHeaders(accessToken),
      })
      console.log("fetched profile!")
      console.log(await res.json())
    }
    async function getUserGroups(accessToken: any) {
      // docs: https://docs.microsoft.com/en-us/graph/api/user-list-joinedteams?view=graph-rest-beta&tabs=http
      const url = "https://graph.microsoft.com/v1.0/me/joinedTeams";

      const res = await fetch(url, {
        method: "GET",
        headers: graphHeaders(accessToken),
      })
      console.log("fetched joined teams?")
      console.log(await res.json())
    }
    async function listGroups(accessToken: any) {
      const url = `https://graph.microsoft.com/beta/groups`;

      const res = await fetch(url, {
        method: "GET",
        headers: graphHeaders(accessToken),
      })
      console.log("list groups?")
      console.log(await res.json())
    }
    async function listChannels(accessToken: any) {
      const url = `https://graph.microsoft.com/beta/teams/${TEAM_ID_PAPERCUPS_TEST}/channels`;

      const res = await fetch(url, {
        method: "GET",
        headers: graphHeaders(accessToken),
      })
      console.log("list channels?")
      console.log(await res.json())
    }
    async function postChatMessage(accessToken: any) {
      const teamId = "8ae730af-1c24-4005-bd83-6326f9a38c62"
      const channelId = "19%3a4ffe109ef79944828b94064aa3069a64%40thread.tacv2"
      const url = `https://graph.microsoft.com/beta/teams/${teamId}/channels/${channelId}/messages`;

      const res = await fetch(url, {
        method: "POST",
        headers: graphHeaders(accessToken),
        body: JSON.stringify({
          contentType: "html",
          content: "Posted via the Graph API!",
        })
      })
      console.log("posted message?")
      console.log(await res.json())
    }
    getUserProfile(accessToken)
    getUserGroups(accessToken)
    //listGroups(accessToken)
    //listChannels(accessToken)
    // fetch teamId, channelId
    //postChatMessage(accessToken)
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
