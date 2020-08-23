defmodule ChatApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ChatApi.Repo,
      # Start the Telemetry supervisor
      ChatApiWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ChatApi.PubSub},
      ChatApiWeb.Presence,
      # Start the Endpoint (http/https)
      ChatApiWeb.Endpoint,
      # Start Oban workers
      {Oban, oban_config()}
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
