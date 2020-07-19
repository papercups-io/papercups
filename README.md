# Papercups

The code behind papercups.io

# One click Heroku deployment

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/papercups-io/papercups)

## Getting started

To start your server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Start the server with `mix phx.server`

## Setting up email alerts

- Set the environment variable in the .env.example
* at the moment we only support amazon SES alerts

This will automatically start up the React frontend in watch mode on `localhost:3000`, with the API running on `localhost:4000`.

### To start client side

The frontend code will start up automatically when you run `mix phx.server`, but for more information see: [README](assets/README.md)

## Running tests

Create postgres test database named: `chat_api_test`

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
