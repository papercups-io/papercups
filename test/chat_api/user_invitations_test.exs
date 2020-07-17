defmodule ChatApi.UserInvitationsTest do
  use ChatApi.DataCase

  alias ChatApi.UserInvitations
  alias ChatApi.Accounts

  describe "user_invitations" do
    alias ChatApi.UserInvitations.UserInvitation

    # @valid_attrs %{expires_at: ~D[2010-04-17]}
    # @update_attrs %{
    #   expires_at: ~D[2011-05-18],
    # }
    # @invalid_attrs %{account_id: nil, expires_at: nil, token: nil}

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
        # |> Enum.into(@valid_attrs)
        |> UserInvitations.create_user_invitation()

      user_invitation
    end

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_user_invitations/0 returns all user_invitations", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert UserInvitations.list_user_invitations() == [user_invitation]
    end

    test "generates dates and token", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert user_invitation.expires_at != nil
      assert user_invitation.token != nil
    end
  end
end
