defmodule ChatApi.UserInvitationsTest do
  use ChatApi.DataCase

  alias ChatApi.UserInvitations
  alias ChatApi.Accounts

  describe "user_invitations" do
    alias ChatApi.UserInvitations.UserInvitation

    @valid_attrs %{expires_at: ~D[2010-04-17], token: "some token"}
    @update_attrs %{
      expires_at: ~D[2011-05-18],
      token: "some updated token"
    }
    @invalid_attrs %{account_id: nil, expires_at: nil, token: nil}

    def fixture(:account) do
      {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
      account
    end

    def valid_create_attrs do
      account = account_fixture()

      Enum.into(@valid_attrs, %{account_id: account.id})
    end

    def account_fixture do
      {:ok, account} = Accounts.create_account(%{company_name: "Test Inc"})
      account
    end

    def user_invitation_fixture(attrs \\ %{}) do
      {:ok, user_invitation} =
        attrs
        |> Enum.into(@valid_attrs)
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

    test "get_user_invitation!/1 returns the user_invitation with given id", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert UserInvitations.get_user_invitation!(user_invitation.id) == user_invitation
    end

    test "create_user_invitation/1 with valid data creates a user_invitation" do
      assert {:ok, %UserInvitation{} = user_invitation} =
               UserInvitations.create_user_invitation(valid_create_attrs())

      assert user_invitation.expires_at == ~D[2010-04-17]
      assert user_invitation.token == "some token"
    end

    test "create_user_invitation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = UserInvitations.create_user_invitation(@invalid_attrs)
    end

    test "update_user_invitation/2 with valid data updates the user_invitation", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert {:ok, %UserInvitation{} = user_invitation} =
               UserInvitations.update_user_invitation(user_invitation, @update_attrs)

      assert user_invitation.expires_at == ~D[2011-05-18]
      assert user_invitation.token == "some updated token"
    end

    test "update_user_invitation/2 with invalid data returns error changeset", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})

      assert {:error, %Ecto.Changeset{}} =
               UserInvitations.update_user_invitation(user_invitation, @invalid_attrs)

      assert user_invitation == UserInvitations.get_user_invitation!(user_invitation.id)
    end

    test "delete_user_invitation/1 deletes the user_invitation", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert {:ok, %UserInvitation{}} = UserInvitations.delete_user_invitation(user_invitation)

      assert_raise Ecto.NoResultsError, fn ->
        UserInvitations.get_user_invitation!(user_invitation.id)
      end
    end

    test "change_user_invitation/1 returns a user_invitation changeset", %{account: account} do
      user_invitation = user_invitation_fixture(%{account_id: account.id})
      assert %Ecto.Changeset{} = UserInvitations.change_user_invitation(user_invitation)
    end
  end
end
