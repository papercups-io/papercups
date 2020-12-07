defmodule ChatApiWeb.SessionControllerTest do
  use ChatApiWeb.ConnCase, async: true

  import ChatApi.Factory

  alias ChatApi.Users
  alias ChatApi.Users.User

  @invalid_params %{"user" => %{"email" => "test@example.com", "password" => "invalid"}}

  setup do
    {:ok, user} =
      params_with_assocs(:user)
      |> with_password_confirmation()
      |> Users.create_user()

    {:ok, user: user}
  end

  def auth_params(%User{} = user) do
    %{"user" => %{"email" => user.email, "password" => user.password}}
  end

  describe "create/2" do
    test "with valid params", %{conn: conn, user: user} do
      conn = post(conn, Routes.session_path(conn, :create, auth_params(user)))

      assert json = json_response(conn, 200)
      assert json["data"]["token"]
      assert json["data"]["renew_token"]
    end

    test "with invalid params", %{conn: conn} do
      conn = post(conn, Routes.session_path(conn, :create, @invalid_params))

      assert json = json_response(conn, 401)
      assert json["error"]["message"] == "Invalid email or password"
      assert json["error"]["status"] == 401
    end

    test "with disabled user", %{conn: conn, user: user} do
      {:ok, _user} = Users.disable_user(user)
      resp = post(conn, Routes.session_path(conn, :create, auth_params(user)))

      assert json = json_response(resp, 401)
      assert "Your account is disabled" <> _msg = json["error"]["message"]
      assert json["error"]["status"] == 401
    end
  end

  describe "renew/2" do
    setup %{conn: conn, user: user} do
      authed_conn = post(conn, Routes.session_path(conn, :create, auth_params(user)))
      :timer.sleep(100)

      {:ok, renewal_token: authed_conn.private[:api_renew_token]}
    end

    test "with valid authorization header", %{conn: conn, renewal_token: token} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", token)
        |> post(Routes.session_path(conn, :renew))

      assert json = json_response(conn, 200)
      assert json["data"]["token"]
      assert json["data"]["renew_token"]
    end

    test "with invalid authorization header", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "invalid")
        |> post(Routes.session_path(conn, :renew))

      assert json = json_response(conn, 401)
      assert json["error"]["message"] == "Invalid token"
      assert json["error"]["status"] == 401
    end

    test "with disabled user", %{conn: conn, user: user, renewal_token: token} do
      {:ok, _user} = Users.disable_user(user)

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", token)
        |> post(Routes.session_path(conn, :renew))

      assert json = json_response(conn, 401)
      assert "Your account is disabled" <> _msg = json["error"]["message"]
      assert json["error"]["status"] == 401
    end
  end

  describe "delete/2" do
    setup %{conn: conn, user: user} do
      authed_conn = post(conn, Routes.session_path(conn, :create, auth_params(user)))
      :timer.sleep(100)
      {:ok, access_token: authed_conn.private[:api_auth_token]}
    end

    test "invalidates", %{conn: conn, access_token: token} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", token)
        |> delete(Routes.session_path(conn, :delete))

      assert json = json_response(conn, 200)
      assert json["data"] == %{}
    end
  end
end
