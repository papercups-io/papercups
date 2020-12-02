redis_enabled =
  case System.get_env("REDIS_URL") do
    "redis://" <> _rest -> true
    _ -> false
  end

exclude = if redis_enabled, do: [], else: [redis: true]

ExUnit.start(exclude: exclude)
Ecto.Adapters.SQL.Sandbox.mode(ChatApi.Repo, :manual)
