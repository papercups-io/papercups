defmodule ChatApiWeb.UserInvitationController do
  use ChatApiWeb, :controller

  alias ChatApi.UserInvitations
  alias ChatApi.UserInvitations.UserInvitation

  plug ChatApiWeb.EnsureRolePlug, :admin when action in [:index, :create, :update]

  action_fallback ChatApiWeb.FallbackController

  def index(conn, _params) do
    with %{account_id: account_id} <- conn.assigns.current_user do
      user_invitations = UserInvitations.list_user_invitations(account_id)
      render(conn, "index.json", user_invitations: user_invitations)
    end
  end

  def create(conn, %{"user_invitation" => _user_invitation_params} = _) do
    current_user = Pow.Plug.current_user(conn)

    with {:ok, %UserInvitation{} = user_invitation} <-
           UserInvitations.create_user_invitation(%{account_id: current_user.account_id}) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_invitation_path(conn, :show, user_invitation))
      |> render("show.json", user_invitation: user_invitation)
    end
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    user_invitation = UserInvitations.get_user_invitation!(id)
    render(conn, "show.json", user_invitation: user_invitation)
  end

  def update(conn, %{"id" => id, "user_invitation" => user_invitation_params}) do
    user_invitation = UserInvitations.get_user_invitation!(id)

    with {:ok, %UserInvitation{} = user_invitation} <-
           UserInvitations.update_user_invitation(user_invitation, user_invitation_params) do
      render(conn, "show.json", user_invitation: user_invitation)
    end
  end

  def delete(conn, %{"id" => id}) do
    user_invitation = UserInvitations.get_user_invitation!(id)

    with {:ok, %UserInvitation{}} <- UserInvitations.delete_user_invitation(user_invitation) do
      send_resp(conn, :no_content, "")
    end
  end
end
