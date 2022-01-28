defmodule ChatApiWeb.UserInvitationEmailController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.{Accounts, Users, UserInvitations}
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

      if send_user_invitation_email_enabled?() do
        user = Users.get_user_info(current_user.account_id, current_user.id)
        account = Accounts.get_account!(current_user.account_id)

        Logger.info("Sending user invitation email to #{to_address}")

        result =
          ChatApi.Emails.send_user_invitation_email(
            user,
            account,
            to_address,
            user_invitation.id
          )

        IO.inspect(result, label: "Sent user invitation email")
      end

      conn
      |> put_status(:created)
      |> json(%{})
    end
  end

  @spec send_user_invitation_email_enabled? :: boolean()
  defp send_user_invitation_email_enabled?() do
    case System.get_env("USER_INVITATION_EMAIL_ENABLED") do
      x when x == "1" or x == "true" -> true
      _ -> false
    end
  end
end
