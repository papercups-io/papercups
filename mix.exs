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
      {:corsica, "~> 1.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:customerio, "~> 0.2"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto_sql, "~> 3.4"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_json_schema, "~> 0.5"},
      {:ex_machina, "~> 2.4", only: [:test]},
      {:floki, "~> 0.30.0"},
      {:gen_smtp, "~> 0.13"},
      {:gettext, "~> 0.11"},
      {:google_api_gmail, "~> 0.13"},
      {:hackney, "~> 1.16"},
      {:jason, "~> 1.0"},
      {:mail, "~> 0.2"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:oauth2, "~> 0.9"},
      {:oban, "~> 2.1.0"},
      {:paginator, "~> 1.0.3"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.2.0"},
      {:phoenix_swagger, "~> 0.8"},
      {:phoenix, "~> 1.5.5"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:pow_postgres_store, "~> 1.0.0-rc2"},
      {:pow, "~> 1.0.18"},
      {:scrivener_ecto, "~> 2.0"},
      {:sentry, "8.0.0"},
      {:stripity_stripe, "~> 2.0"},
      {:swoosh, "~> 1.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:tesla, "~> 1.3"},
      {:tzdata, "~> 1.0.5"},
      {:uuid, "~> 1.1"}
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
