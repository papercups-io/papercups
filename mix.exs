defmodule ChatApi.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_api,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        papercups: [
          include_executables_for: [:unix],
          applications: [chat_api: :permanent]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ChatApi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_machina, "~> 2.4", only: [:test]},
      {:mock, "~> 0.3.0", only: :test},
      {:customerio, "~> 0.2"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws_lambda, "~> 2.0"},
      {:swoosh, "~> 1.0"},
      {:gen_smtp, "~> 0.13"},
      {:phoenix, "~> 1.5.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:tesla, "~> 1.3"},
      {:hackney, "~> 1.17"},
      {:jason, "~> 1.0"},
      {:joken, "~> 2.0"},
      {:plug_cowboy, "~> 2.0"},
      {:corsica, "~> 1.0"},
      {:pow, "~> 1.0.18"},
      {:stripity_stripe, "~> 2.0"},
      {:oban, "~> 2.1.0"},
      {:sentry, "8.0.0"},
      {:google_api_gmail, "~> 0.13"},
      {:oauth2, "~> 0.9"},
      {:mail, "~> 0.2"},
      {:phoenix_swagger, "~> 0.8"},
      {:uuid, "~> 1.1"},
      {:ex_json_schema, "~> 0.5"},
      {:pow_postgres_store, "~> 1.0.0-rc2"},
      {:tzdata, "~> 1.0.5"},
      {:scrivener_ecto, "~> 2.0"},
      {:floki, "~> 0.30.0"},
      {:paginator, "~> 1.0.3"},
      {:phoenix_pubsub_redis, "~> 3.0.0"},
      {:appsignal_phoenix, "~> 2.0.0"},
      {:earmark, "~> 1.4.15"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
