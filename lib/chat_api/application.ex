defmodule ChatApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    pub_sub_opts =
      case redis_url() do
        "rediss://" <> _url ->
          [
            name: ChatApi.PubSub,
            adapter: Phoenix.PubSub.Redis,
            # NB: use redis://localhost:6379 for testing locally
            url: redis_url(),
            node_name: node_name() |> IO.inspect(label: "Running Redis adapter on node:"),
            # Set ssl: true when using `rediss` URLs in Heroku
            ssl: true,
            socket_opts: [verify: :verify_none]
          ]

        "redis://" <> _url ->
          [
            name: ChatApi.PubSub,
            adapter: Phoenix.PubSub.Redis,
            # NB: use redis://localhost:6379 for testing locally
            url: redis_url(),
            node_name: node_name() |> IO.inspect(label: "Running Redis adapter on node:")
          ]

        _ ->
          [name: ChatApi.PubSub]
      end

    IO.inspect(pub_sub_opts, label: "Inspecting PubSub configuration:")

    children = [
      # Start the Ecto repository
      ChatApi.Repo,
      # Start the Telemetry supervisor
      ChatApiWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, pub_sub_opts},
      ChatApiWeb.Presence,
      # Start the Endpoint (http/https)
      ChatApiWeb.Endpoint,
      # Start Oban workers
      {Oban, oban_config()},
      # Automatically delete expired session records
      {Pow.Postgres.Store.AutoDeleteExpired, [interval: :timer.hours(1)]}
      # Start a worker by calling: ChatApi.Worker.start_link(arg)
      # {ChatApi.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChatApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChatApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Conditionally disable crontab, queues, or plugins here.
  defp oban_config do
    Application.get_env(:chat_api, Oban)
  end

  defp redis_url do
    System.get_env("REDIS_TLS_URL") || System.get_env("REDIS_URL")
  end

  defp node_name do
    # TODO: this might not be reliable (see https://devcenter.heroku.com/articles/dynos#local-environment-variables)
    fallback =
      System.get_env("NODE") || System.get_env("DYNO") ||
        Base.encode16(:crypto.strong_rand_bytes(6))

    IO.inspect(node(), label: "Checking node() for Redis adapter:")

    case node() do
      nil -> fallback
      :nonode@nohost -> fallback
      n -> n
    end
  end
end
