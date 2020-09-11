defmodule ChatApiWeb.UserController do
  use ChatApiWeb, :controller
  alias ChatApi.Users
  require Logger

  action_fallback ChatApiWeb.FallbackController

  def verify_email(conn, %{"token" => token}) do
    case Users.find_by_email_confirmation_token(token) do
      nil ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid verification token"}})

      %{email_confirmed_at: nil} = user ->
        case Users.verify_email(user) do
          {:ok, _user} -> json(conn, %{data: %{success: true}})
          {:error, reason} -> json(conn, %{data: %{success: false, message: reason}})
        end

      _user ->
        json(conn, %{data: %{success: true, message: "Email already verified!"}})
    end
  end

  def create_password_reset(conn, %{"email" => email}) do
    case Users.find_user_by_email(email) do
      nil ->
        json(conn, %{data: %{ok: true}})

      user ->
        case Users.send_password_reset_email(user) do
          {:ok, result} ->
            Logger.info("Successfully sent password reset email: #{inspect(result)}")

            json(conn, %{data: %{ok: true}})

          {:warning, reason} ->
            Logger.warn(reason)

            json(conn, %{data: %{ok: true}})

          error ->
            Logger.error(error)

            json(conn, %{data: %{ok: false}})
        end
    end
  end

  def reset_password(conn, %{"token" => token} = params) do
    case Users.find_by_password_reset_token(token) do
      nil ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid or expired password reset link"}})

      user ->
        case Users.update_password(user, params) do
          {:ok, user} -> json(conn, %{data: %{success: true, email: user.email}})
          {:error, reason} -> json(conn, %{data: %{success: false, message: reason}})
        end
    end
  end
end
