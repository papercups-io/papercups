defmodule ChatApi.TagsTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.Tags

  describe "tags" do
    alias ChatApi.Tags.Tag

    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    setup do
      account = insert(:account)
      tag = insert(:tag, account: account)

      {:ok, account: account, tag: tag}
    end

    test "list_tags/0 returns all tags", %{account: account, tag: tag} do
      tag_ids = Tags.list_tags(account.id) |> Enum.map(& &1.id)

      assert tag_ids == [tag.id]
    end

    test "get_tag!/1 returns the tag with given id", %{tag: tag} do
      assert tag == Tags.get_tag!(tag.id) |> Repo.preload([:account])
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Tags.create_tag(params_with_assocs(:tag, name: "new tag"))
      assert tag.name == "new tag"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tags.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag", %{tag: tag} do
      assert {:ok, %Tag{} = tag} = Tags.update_tag(tag, @update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset",
         %{tag: tag} do
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(tag, @invalid_attrs)
      assert tag == Tags.get_tag!(tag.id) |> Repo.preload([:account])
    end

    test "delete_tag/1 deletes the tag", %{tag: tag} do
      assert {:ok, %Tag{}} = Tags.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset", %{tag: tag} do
      assert %Ecto.Changeset{} = Tags.change_tag(tag)
    end
  end
end
