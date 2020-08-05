## Setting up Slack

If you plan on self-hosting Papercups, you'll need to set up your own Slack app if you want to handle messaging through Slack.

### Creating the app

- Go to https://api.slack.com/apps
- Click “Create New App”
- Name it whatever you’d like, and pick the Slack workspace you’d like to test it against

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320538271_Screen+Shot+2020-08-01+at+6.03.09+PM.png)

### Subscribing to Slack events

- Go to “Event Subscriptions”
- Toggle “Enable Events” to “On”
- Input your webhook URL in the “Request URL” input
  - It should look like `https://YOUR_APP_HOST/api/slack/webhook`
  - In my case, this was `https://alex-papercups-staging.herokuapp.com/api/slack/webhook`

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320537804_Screen+Shot+2020-08-01+at+6.12.53+PM.png)

- Subscribe to the `message.channels` bot event
- Subscribe to the `message.channels` user event

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320538144_Screen+Shot+2020-08-01+at+6.07.39+PM.png)

### Setting up scopes and permissions

- Go to “OAuth & Permissions”
- Click the “Install App to Workspace” button to install your app to your test workspace if you haven’t already

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320538113_Screen+Shot+2020-08-01+at+6.08.22+PM.png)

- Add the redirect URL we’ll be using in the dashboard
  - It should look like `https://YOUR_APP_HOST/integrations/slack`
  - In my case, this was `https://alex-papercups-staging.herokuapp.com/integrations/slack`

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320538064_Screen+Shot+2020-08-01+at+6.09.48+PM.png)

- Add the bot scopes we’ll be using
  - `channels:history`
  - `channels:manage`
  - `chat:write`
  - `chat:write.public`
  - `incoming-webhook`

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596321782791_Screen+Shot+2020-08-01+at+6.42.16+PM.png)

- Add the user scopes we’ll be using
  - `channels:history`

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596321782746_Screen+Shot+2020-08-01+at+6.42.23+PM.png)

### Enabling distribution of your app

- Set up your app for distribution
- Under “Basic Information”, go to the “Manage distribution” section and click “Distribute App”

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320537957_Screen+Shot+2020-08-01+at+6.11.10+PM.png)

- Indicate that hard-coded information has been removed from your code
  - (We’ve handled this for you!)

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320537879_Screen+Shot+2020-08-01+at+6.11.42+PM.png)

- Click on “Activate Public Distribution”

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320537770_Screen+Shot+2020-08-01+at+6.13.12+PM.png)

### Setting up your environment variables

- In the “Basic Information” section, scroll down to “App Credentials” to get the keys you’ll be using as environment variables

![](https://paper-attachments.dropbox.com/s_63895AAB3973EA701984146FF05B40938812C8B7E2ACDD7574570851E5FDF9D0_1596320537710_Screen+Shot+2020-08-01+at+6.13.39+PM.png)

- Export the following environment variables:

```
export PAPERCUPS_SLACK_CLIENT_ID='YOUR_CLIENT_ID_HERE'
export REACT_APP_SLACK_CLIENT_ID='YOUR_CLIENT_ID_HERE'
export PAPERCUPS_SLACK_CLIENT_SECRET='YOUR_CLIENT_SECRET_HERE'
```

- If you're using Heroku, set the environment variables on the `config`:

```
heroku config:set PAPERCUPS_SLACK_CLIENT_ID='YOUR_CLIENT_ID_HERE'
heroku config:set REACT_APP_SLACK_CLIENT_ID='YOUR_CLIENT_ID_HERE'
heroku config:set PAPERCUPS_SLACK_CLIENT_SECRET='YOUR_CLIENT_SECRET_HERE'
```

### Testing

- Go to the `/integrations` path in your dashboard
- Click on "Connect" for Slack

<img width="1186" alt="Screen Shot 2020-08-03 at 7 00 57 PM" src="https://user-images.githubusercontent.com/5264279/89235340-f9840180-d5bb-11ea-9a64-0495dcdd53b9.png">

- Go through the OAuth flow for your app
- Select a channel to connect with

<img width="1186" alt="Screen Shot 2020-08-03 at 7 01 18 PM" src="https://user-images.githubusercontent.com/5264279/89235339-f9840180-d5bb-11ea-9013-16d3d0ab73a1.png">

- If successful, it should take you back to this page:

<img width="1186" alt="Screen Shot 2020-08-03 at 7 01 24 PM" src="https://user-images.githubusercontent.com/5264279/89235336-f9840180-d5bb-11ea-83c6-d7edf9fcb039.png">

- To test that it works, go to the "Getting started" tab
- Try sending a message in the widget on the right:

<img width="1066" alt="Screen Shot 2020-08-03 at 7 08 58 PM" src="https://user-images.githubusercontent.com/5264279/89235757-d3129600-d5bc-11ea-8331-509ce15496a2.png">

- Check Slack to verify you received a message
- Try sending a reply through Slack

<img width="379" alt="Screen Shot 2020-08-03 at 7 10 32 PM" src="https://user-images.githubusercontent.com/5264279/89235854-081ee880-d5bd-11ea-888f-e44c3d6ec9ae.png">

- Verify that the reply was received

<img width="1186" alt="Screen Shot 2020-08-03 at 7 11 03 PM" src="https://user-images.githubusercontent.com/5264279/89235882-18cf5e80-d5bd-11ea-9d66-9b8630494c68.png">

### Done!

That should be it! Feel free to open an issue if you have any problems getting set up :)
