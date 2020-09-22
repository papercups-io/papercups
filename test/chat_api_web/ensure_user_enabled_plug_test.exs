defmodule ChatApiWeb.EnsureUserEnabledPlugTest do
  use ChatApiWeb.ConnCase

  alias ChatApi.Users.User
  alias ChatApiWeb.EnsureUserEnabledPlug

  @pow_config [otp_app: :my_app]
  @user %User{id: 1, disabled_at: nil}
  @disabled_user %User{id: 2, disabled_at: DateTime.utc_now()}
  @plug_opts []

  setup do
    {:ok, conn: init_conn()}
  end

  test "call/2 with no user", %{conn: conn} do
    opts = EnsureUserEnabledPlug.init(@plug_opts)
    conn = EnsureUserEnabledPlug.call(conn, opts)

    refute conn.halted
  end

  test "call/2 with user", %{conn: conn} do
    opts = EnsureUserEnabledPlug.init(@plug_opts)

    conn =
      conn
      |> Pow.Plug.assign_current_user(@user, @pow_config)
      |> EnsureUserEnabledPlug.call(opts)

    refute conn.halted
  end

  test "call/2 with disabled user", %{conn: conn} do
    opts = EnsureUserEnabledPlug.init(@plug_opts)

    conn =
      conn
      |> Pow.Plug.assign_current_user(@disabled_user, @pow_config)
      |> EnsureUserEnabledPlug.call(opts)

    assert conn.halted
    assert conn.status == 401
  end

  defp init_conn() do
    pow_config = Keyword.put(@pow_config, :plug, Pow.Plug.Session)

    :get
    |> Plug.Test.conn("/")
    |> Plug.Test.init_test_session(%{})
    |> Pow.Plug.put_config(pow_config)
    |> Phoenix.Controller.fetch_flash()
  end
end
