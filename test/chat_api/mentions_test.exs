defmodule ChatApi.MentionsTest do
  use ChatApi.DataCase
  import ChatApi.Factory
  alias ChatApi.Mentions

  describe "mentions" do
    alias ChatApi.Mentions.Mention

    @valid_attrs %{seen_at: ~U[2021-01-06 10:00:00Z]}
    @update_attrs %{seen_at: ~U[2021-02-06 10:00:00Z]}
    @invalid_attrs %{account_id: nil, conversation_id: nil, message_id: nil}

    setup do
      account = insert(:account)
      mention = insert(:mention, account: account)

      {:ok, account: account, mention: mention}
    end

    test "list_mentions/1 returns all mentions for the given account", %{
      account: account,
      mention: mention
    } do
      mention_ids = Mentions.list_mentions(account.id) |> Enum.map(& &1.id)

      assert mention_ids == [mention.id]
    end

    test "get_mention!/1 returns the mention with given id", %{mention: mention} do
      result = Mentions.get_mention!(mention.id)

      assert mention.id == result.id
      assert mention.seen_at == result.seen_at
      assert mention.conversation_id == result.conversation_id
      assert mention.message_id == result.message_id
      assert mention.user_id == result.user_id
    end

    test "create_mention/1 with valid data creates a mention" do
      assert {:ok, %Mention{} = mention} =
               Mentions.create_mention(params_with_assocs(:mention, Map.to_list(@valid_attrs)))

      assert mention.seen_at == @valid_attrs.seen_at
    end

    test "create_mention/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Mentions.create_mention(@invalid_attrs)
    end

    test "update_mention/2 with valid data updates the mention", %{mention: mention} do
      assert {:ok, %Mention{} = mention} = Mentions.update_mention(mention, @update_attrs)

      assert mention.seen_at == @update_attrs.seen_at
    end

    test "update_mention/2 with invalid data returns error changeset", %{mention: mention} do
      assert {:error, %Ecto.Changeset{}} = Mentions.update_mention(mention, @invalid_attrs)

      current = Mentions.get_mention!(mention.id)

      assert mention.id == current.id
      assert mention.seen_at == current.seen_at
      assert mention.account_id == current.account_id
      assert mention.conversation_id == current.conversation_id
      assert mention.message_id == current.message_id
      assert mention.user_id == current.user_id
    end

    test "delete_mention/1 deletes the mention", %{mention: mention} do
      assert {:ok, %Mention{}} = Mentions.delete_mention(mention)
      assert_raise Ecto.NoResultsError, fn -> Mentions.get_mention!(mention.id) end
    end

    test "change_mention/1 returns a mention changeset", %{mention: mention} do
      assert %Ecto.Changeset{} = Mentions.change_mention(mention)
    end
  end
end
