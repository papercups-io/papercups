defmodule ChatApiWeb.UserInvitationEmailController do
  use ChatApiWeb, :controller

  alias ChatApi.{Accounts, UserInvitations}
  alias ChatApi.UserInvitations.UserInvitation

  plug ChatApiWeb.EnsureRolePlug, :admin when action in [:create]

  action_fallback ChatApiWeb.FallbackController

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"to_address" => to_address}) do
    current_user = Pow.Plug.current_user(conn)

    # TODO: consolidate logic related to checking user capacity in controllers.
    if Accounts.has_reached_user_capacity?(current_user.account_id) do
      conn
      |> put_status(403)
      |> json(%{
        error: %{
          status: 403,
          message:
            "You've hit the user limit for our free tier. " <>
              "Try the premium plan free for 14 days to invite more users to your account!"
        }
      })
    else
      {:ok, %UserInvitation{} = user_invitation} =
        UserInvitations.create_user_invitation(%{account_id: current_user.account_id})

      enqueue_user_invitation_email(
        current_user.id,
        current_user.account_id,
        to_address,
        user_invitation.id
      )

      conn
      |> put_status(:created)
      |> json(%{})
    end
  end

  def enqueue_user_invitation_email(user_id, account_id, to_address, invitation_token) do
    %{
      user_id: user_id,
      account_id: account_id,
      to_address: to_address,
      invitation_token: invitation_token
    }
    |> ChatApi.Workers.SendUserInvitationEmail.new()
    |> Oban.insert()
  end
end
