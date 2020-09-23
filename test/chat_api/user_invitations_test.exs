defmodule ChatApi.UserInvitationsTest do
  use ChatApi.DataCase, async: true

  alias ChatApi.UserInvitations

  describe "user_invitations" do
    setup do
      account = account_fixture()
      user_invitation = user_invitation_fixture(account)

      {:ok, account: account, user_invitation: user_invitation}
    end

    test "list_user_invitations/1 returns all user_invitations", %{
      account: account,
      user_invitation: user_invitation
    } do
      assert UserInvitations.list_user_invitations(account.id) == [user_invitation]
    end

    test "generates dates and token", %{user_invitation: user_invitation} do
      assert user_invitation.expires_at != nil
    end

    test "sets invitation as expired", %{user_invitation: user_invitation} do
      {_, user_invitation} =
        user_invitation
        |> UserInvitations.expire_user_invitation()

      assert UserInvitations.expired?(user_invitation) == true
    end
  end
end
