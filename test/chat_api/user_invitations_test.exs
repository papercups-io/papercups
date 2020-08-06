defmodule ChatApi.UserInvitationsTest do
  use ChatApi.DataCase

  alias ChatApi.{Accounts, UserInvitations}

  describe "user_invitations" do
    def fixture(:account) do
      {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
      account
    end

    def valid_create_attrs do
      account = account_fixture()
      %{account_id: account.id}
    end

    def account_fixture do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})
      account
    end

    def user_invitation_fixture(attrs \\ %{}) do
      {:ok, user_invitation} =
        attrs
        |> UserInvitations.create_user_invitation()

      user_invitation
    end

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_user_invitations/1 returns all user_invitations", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert UserInvitations.list_user_invitations(account.id) == [user_invitation]
    end

    test "generates dates and token", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert user_invitation.expires_at != nil
    end

    test "sets invitation as expired", %{account: account} do
      {_, user_invitation} =
        user_invitation_fixture(%{account_id: account.id})
        |> UserInvitations.expire_user_invitation()

      assert UserInvitations.expired?(user_invitation) == true
    end
  end
end
