defmodule ChatApiWeb.RegistrationController do
  use ChatApiWeb, :controller

  alias Ecto.Changeset
  alias Plug.Conn
  alias ChatApiWeb.ErrorHelpers

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, params)

  def create(conn, %{"user" => user_params}) when is_map_key(user_params, "invite_token") do
    try do
      invite = ChatApi.UserInvitations.get_user_invitation!(user_params["invite_token"])
      params = Enum.into(user_params, %{"account_id" => invite.account.id})
      conn
      |> Pow.Plug.create_user(params)
      |> case do
           {:ok, _user, conn} ->
             ChatApi.UserInvitations.delete_user_invitation(invite)
             send_api_token(conn)

           {:error, changeset, conn} ->
             errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
             send_user_create_errors(conn, errors)
         end
    rescue
      Ecto.NoResultsError ->
       conn
       |> put_status(500)
       |> json(%{error: %{status: 500, message: "Invalid invitation token"}})
    end
  end

  def create(conn, %{"user" => user_params}) do
      {:ok, account} =
          ChatApi.Accounts.create_account(%{company_name: user_params["company_name"]})

    params = Enum.into(user_params, %{"account_id" => account.id})
    conn
    |> Pow.Plug.create_user(params)
    |> case do
         {:ok, _user, conn} ->
           send_api_token(conn)

         {:error, changeset, conn} ->
           errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)
           send_user_create_errors(conn, errors)
       end
  end

  defp send_api_token(conn) do
    json(conn, %{
      data: %{
        token: conn.private[:api_auth_token],
        renew_token: conn.private[:api_renew_token]
      }
    })
  end

  defp send_user_create_errors(conn, errors) do
    conn
    |> put_status(500)
    |> json(%{error: %{status: 500, message: "Couldn't create user", errors: errors}})
  end
end
