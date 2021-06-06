defmodule ChatApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    pub_sub_opts =
      case System.get_env("REDIS_URL") do
        "redis://" <> _url ->
          [
            name: ChatApi.PubSub,
            adapter: Phoenix.PubSub.Redis,
            # NB: use redis://localhost:6379 for testing locally
            url: System.get_env("REDIS_URL"),
            node_name: System.get_env("PAPERCUPS_REDIS_PUBSUB_NODE", "Phoenix.PubSub.RedisServer")
          ]

        _ ->
          [name: ChatApi.PubSub]
      end

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
end
