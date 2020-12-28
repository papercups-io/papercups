### Teams OAuth

Good news:

- the MS Graph API does allow you to send messages AND reply to messages in a channel *currently in beta
  - See [Create Message in Channel](https://docs.microsoft.com/en-us/graph/api/channel-post-message?view=graph-rest-beta&tabs=http)
  - See [Reply to a Message in Channel](https://docs.microsoft.com/en-us/graph/api/channel-post-messagereply?view=graph-rest-beta&tabs=http)

Bad news:

- this functionality is enabled only for "work/school" MS users (no personal MS accounts, even if delegated/linked)
  - See [Permissions for ChatMessage](https://docs.microsoft.com/en-us/graph/api/channel-post-message?view=graph-rest-beta&tabs=http#permissions)

#### Accessing /messages/:id/replies

I believe if we set the app up as an "Application" (ie a Bot), the application can have access to create/reply endpoints.

If we set the app up as a user-based OAuth app, we can also send/reply to messages, but only if the user is a member of an MS group ("work/school" account).

(FWIW: I believe this is due to the way the Graph API is implemented in MS's backend - "work/school" accounts are related to Office365/Outlook "group/organization" accounts, while personal accounts are not).

#### Making calls to the MS Graph API

The /Teams component contains a spike on obtaining an MS Graph access token and making requests to the Graph API (/me, /messages, /messages/:id/replies)

1. Get an accessToken (either by User-based OAuth, or via app-based OAuth (eg, a Bot))
1. Fetch any required data (Team ID, Channel ID, Message ID) either by request or via URI
1. Make request

#### Gotchas

1. The /beta API opens up some endpoints that do not exist in /v1 (notably /messages/:id/reply)
1. Some endpoints are not available to requests auth'd with MS personal accounts (see Permissions docs for each endpoint)
1. For a Graph request to work, A) the MS Graph "App" has to be granted the appropriate permissions in the Azure console;
1. and B) the access token has to request the corresponding Scopes for that permission when requesting the accessToken
1. Other than that, pretty much all requests should be available via the /beta MSGraph API endpoint
