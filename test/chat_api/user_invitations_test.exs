defmodule ChatApi.UserInvitationsTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.UserInvitations

  describe "user_invitations" do
    setup do
      account = insert(:account)
      user_invitation = insert(:user_invitation, account: account)

      {:ok, account: account, user_invitation: user_invitation}
    end

    test "list_user_invitations/1 returns all user_invitations",
         %{account: account, user_invitation: user_invitation} do
      invitation_ids =
        UserInvitations.list_user_invitations(account.id)
        |> Enum.map(& &1.id)

      assert invitation_ids == [user_invitation.id]
    end

    test "generates dates and token", %{user_invitation: user_invitation} do
      assert user_invitation.expires_at != nil
    end

    test "sets invitation as expired", %{user_invitation: user_invitation} do
      {:ok, user_invitation} =
        user_invitation
        |> UserInvitations.expire_user_invitation()

      assert UserInvitations.expired?(user_invitation) == true
    end
  end
end
