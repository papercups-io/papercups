defmodule ChatApi.InboxesTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.Inboxes

  describe "inboxes" do
    alias ChatApi.Inboxes.Inbox

    @update_attrs %{
      name: "some updated name",
      description: "some updated description",
      is_private: true
    }
    @invalid_attrs %{
      name: nil
    }

    setup do
      account = insert(:account)
      inbox = insert(:inbox, account: account)

      {:ok, account: account, inbox: inbox}
    end

    test "list_inboxes/1 returns all inboxes", %{
      account: account,
      inbox: inbox
    } do
      inbox_ids =
        Inboxes.list_inboxes(account.id)
        |> Enum.map(& &1.id)

      assert inbox_ids == [inbox.id]
    end

    test "get_inbox!/1 returns the inbox with given id", %{
      inbox: inbox
    } do
      found_inbox =
        Inboxes.get_inbox!(inbox.id)
        |> Repo.preload([:account])

      assert found_inbox == inbox
    end

    test "create_inbox/1 with valid data creates a inbox", %{
      account: account
    } do
      attrs =
        params_with_assocs(:inbox,
          account: account,
          name: "Primary Inbox",
          is_primary: true
        )

      assert {:ok, %Inbox{name: "Primary Inbox", is_primary: true}} = Inboxes.create_inbox(attrs)
    end

    test "create_inbox/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inboxes.create_inbox(@invalid_attrs)
    end

    test "update_inbox/2 with valid data updates the inbox", %{
      inbox: inbox
    } do
      assert {:ok, %Inbox{} = inbox} = Inboxes.update_inbox(inbox, @update_attrs)

      assert inbox.name == "some updated name"
      assert inbox.description == "some updated description"
      assert inbox.is_private
    end

    test "update_inbox/2 with invalid data returns error changeset", %{
      inbox: inbox
    } do
      assert {:error, %Ecto.Changeset{}} = Inboxes.update_inbox(inbox, @invalid_attrs)

      assert inbox ==
               Inboxes.get_inbox!(inbox.id)
               |> Repo.preload([:account])
    end

    test "delete_inbox/1 deletes the inbox", %{
      inbox: inbox
    } do
      assert {:ok, %Inbox{}} = Inboxes.delete_inbox(inbox)

      assert_raise Ecto.NoResultsError, fn ->
        Inboxes.get_inbox!(inbox.id)
      end
    end

    test "change_inbox/1 returns a inbox changeset", %{
      inbox: inbox
    } do
      assert %Ecto.Changeset{} = Inboxes.change_inbox(inbox)
    end
  end
end
