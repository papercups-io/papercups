# Papercups

Papercups is an open source live customer chat web app. We offer a hosted version at [app.papercups.io](https://app.papercups.io/).

You can check out how our chat widget looks and play around with customizing it on our [demo page](https://app.papercups.io/demo/). The chat widget component is also open sourced at [github.com/papercups-io/chat-widget](https://github.com/papercups-io/chat-widget).

_Watch how easy it is to get set up with our Slack integration 🚀 :_
![slack-setup](https://user-images.githubusercontent.com/4218509/88716918-a0583180-d0d4-11ea-93b3-12437ac51138.gif)

## One click Heroku deployment

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/papercups-io/papercups)

## Philosophy

We wanted to make a self-hosted version of tools like Intercom and Drift for companies that have privacy and security concerns about having customer data going to third party services. We’re starting with chat right now but we want to expand into all forms of customer communication like email campaigns and push notifications.

Stay tuned! We'll be posting a more detailed roadmap soon 🤓

## Documentation

[Development Setup](https://github.com/papercups-io/papercups/wiki/Development-Setup#getting-started)

## Get in touch

Come say hi to us on [Slack](https://join.slack.com/t/papercups-io/shared_invite/zt-gfs0d269-dEHm3SYs_5KmFKQ9YhBzDw) or [Discord](https://discord.gg/Dq2A3eh)! :wave:

## Setting up email alerts

Set the environment variables in the [`.env.example`](https://github.com/papercups-io/papercups/blob/master/.env.example) file.

At the moment we only support [Mailgun](https://www.mailgun.com/) — other messaging channels are coming soon!

## Deploying

We currently use Heroku for deployments. (This is for internal use only.)

```
git push heroku master
heroku run "POOL_SIZE=2 mix ecto.migrate"
```

## Learn more about Phoenix

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
