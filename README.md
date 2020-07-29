# Papercups

Papercups is an open source live customer chat web app. We offer a hosted version at [app.papercups.io](https://app.papercups.io/)

You can check out how our widget looks at our [demo page](https://app.papercups.io/demo/)

Our chat widget is also open sourced at [github.com/papercups-io/chat-widget](https://github.com/papercups-io/chat-widget)

![slack-setup](https://user-images.githubusercontent.com/4218509/88716918-a0583180-d0d4-11ea-93b3-12437ac51138.gif)

## One click Heroku deployment

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/papercups-io/papercups)


## Philosophy

We wanted to make a self hosted version of tools like intercom and drift for companies that have privacy and security concerns about having customer data going to third party services. We’re starting with chat right now but we want to expand in to all forms of customer communication like email campaigns and push notifications. 

## Getting started

To start your server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Start the server with `mix phx.server`

This will automatically start up the React frontend in watch mode on `localhost:3000`, with the API running on `localhost:4000`.

### To start client side

The frontend code will start up automatically when you run `mix phx.server`, but for more information see: [assets/README.md](assets/README.md)

## Setting up email alerts

Set the environment variables in the [`.env.example`](https://github.com/papercups-io/papercups/blob/master/.env.example) file.

At the moment we only support [Mailgun](https://www.mailgun.com/) — other messaging channels are coming soon!

## Running tests

Create a PostgreSQL test database named: `chat_api_test`, and run:

```
mix test
```

## Deploying

We currently use Heroku for deployments:

```
git push heroku master
```

## Running compiler on file change

_Note_: Make sure you are running this inside of ChatApi otherwise it'll trigger on UI changes

```
./scripts/compile_watch.sh
```

## Learn more about Phoenix

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
