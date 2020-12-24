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

/*
 *    OAuth Helpers
 */
async function acquireTokenOrRedirect(msClient: any, signedInUser: any) {
  try {
    const accessTokenResponse = await msClient.acquireTokenSilent({
      account: signedInUser,
      scopes: DESIRED_SCOPES,
    })
    return accessTokenResponse
  }
  catch (error) {
    if (error.errorMessage.indexOf("interaction_required") !== -1) {
      console.log("redirecting to acquire token")
      await msClient.acquireTokenRedirect({
        scopes: DESIRED_SCOPES,
      });
    }
  }
}

function allowUserAccountSelection() {
  // on Oauth, if a user has multiple Microsoft accounts, allow the user to select an account
  /*
  const currentAccounts = await msClient.getAllAccounts();
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
async function handleOauth(msClient: any) {
  let signedInUser
  let accessToken

  // try parsing code & token from query params
  try {
    const tokenResponse = await msClient.handleRedirectPromise()
    console.log("Got token response!")
    console.log(tokenResponse)

    if (tokenResponse) {
      signedInUser = tokenResponse.account;
    } else {
      signedInUser = await msClient.getAllAccounts()[0]
    }
    console.log("retrieved user", signedInUser)

    // have user and token, attempt get token
    if (signedInUser && tokenResponse) {
      console.log("successful sign in!")
      console.log(signedInUser)
    } else if (signedInUser) {
      console.log("signed in, but no access tokens?")
      const accessTokenResponse = await acquireTokenOrRedirect(msClient, signedInUser)
      console.log("ACCESS TOKEN RESPONSE")
      console.log(accessTokenResponse)
      accessToken = accessTokenResponse.accessToken
    } else {
      console.log("no sign-in, or tokenResponse - redirecting to SSO")
      await msClient.loginRedirect({
        scopes: DESIRED_SCOPES,
      });
    }
  }
  catch (error) {
    console.log("failed to handleRedirectPromise", error)
  }
  return [signedInUser, accessToken]
}

/*
 *    MS Graph Helpers
 *    Require:
 *    - application can grant required permissions (https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/44ffc9f2-4c63-4bf6-92d6-b84d930c0a73/isMSAApp/)
 *    - OAuth'd user has obtained the required scopes (DESIRED_SCOPES here)
 *
 *    **Some Graph APIs only allow "work/school" MS users to obtain the desired scopes**
 */
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
  // TODO: this TeamId is a guess inferred from URI, instead fetch it via ListGroups above
  // TODO: this ChannelId is a guess inferred from URI, instead fetch it via ListChannels above
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


class Register extends React.Component<Props, State> {
  state: State = {
  };

  async componentDidMount() {
    const oauthConfig = {
      auth: {
        // currently the "Papercups - any org directory" app: https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/RegisteredApps
        clientId: '44ffc9f2-4c63-4bf6-92d6-b84d930c0a73',
        redirectUri: "http://localhost:3500/teams",
        postLogoutRedirectUri: "http://localhost:3500/",
        authority: "https://login.microsoftonline.com/common",
        // TODO: logout route that clears MS AD state from server: https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-spa-sign-in?tabs=javascript2#sign-out
      },
      // caches the refresh token on user's browser
      // --> look at server-side oauth if we want to avoid this?
      cache: {
        cacheLocation: 'localStorage',
        storeAuthStateInCookie: true
      }
    }
    const msClient = new msal.PublicClientApplication(oauthConfig);

    // attempt to get access code via redirect
    let signedInUser, accessToken = await handleOauth(msClient)

    // attempt to use accessToken
    getUserProfile(accessToken)
    getUserGroups(accessToken)
    //listGroups(accessToken)
    //listChannels(accessToken)
    //postChatMessage(accessToken)  // requires TeamId, ChannelId
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
