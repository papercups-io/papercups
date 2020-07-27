defmodule ChatApiWeb.RegistrationController do
  use ChatApiWeb, :controller

  alias Ecto.Changeset
  alias Plug.Conn
  alias ChatApiWeb.ErrorHelpers

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    invite_token = user_params["invite_token"]

    account =
      if(invite_token) do
        ChatApi.UserInvitations.get_user_invitation!(user_params["invite_token"]).account
      else
        {:ok, account} =
          ChatApi.Accounts.create_account(%{company_name: user_params["company_name"]})

        account
      end

    params = Enum.into(user_params, %{"account_id" => account.id})

    conn
    |> Pow.Plug.create_user(params)
    |> case do
      {:ok, _user, conn} ->
        json(conn, %{
          data: %{
            token: conn.private[:api_auth_token],
            renew_token: conn.private[:api_renew_token]
          }
        })

      {:error, changeset, conn} ->
        errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

        conn
        |> put_status(500)
        |> json(%{error: %{status: 500, message: "Couldn't create user", errors: errors}})
    end
  end
end
