defmodule ChatApiWeb.RegistrationController do
  use ChatApiWeb, :controller

  alias Ecto.Changeset
  alias Plug.Conn
  alias ChatApiWeb.ErrorHelpers

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    # TODO: for now we just create a new account for every new signup
    # In the future we'll want to be able to invite users to existing accounts
    {:ok, account} = ChatApi.Accounts.create_account(user_params)
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
