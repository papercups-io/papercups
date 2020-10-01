defmodule ChatApi.TagsTest do
  use ChatApi.DataCase

  alias ChatApi.Tags

  describe "tags" do
    alias ChatApi.Tags.Tag

    @valid_attrs %{name: "some name"}
    @update_attrs %{name: "some updated name"}
    @invalid_attrs %{name: nil}

    setup do
      account = account_fixture()

      {:ok, account: account}
    end

    test "list_tags/0 returns all tags", %{account: account} do
      tag = tag_fixture(account)
      assert Tags.list_tags(account.id) == [tag]
    end

    test "get_tag!/1 returns the tag with given id", %{account: account} do
      tag = tag_fixture(account)
      assert Tags.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag", %{account: account} do
      params = Map.merge(@valid_attrs, %{account_id: account.id})
      assert {:ok, %Tag{} = tag} = Tags.create_tag(params)
      assert tag.name == "some name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tags.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag", %{account: account} do
      tag = tag_fixture(account)
      assert {:ok, %Tag{} = tag} = Tags.update_tag(tag, @update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset", %{account: account} do
      tag = tag_fixture(account)
      assert {:error, %Ecto.Changeset{}} = Tags.update_tag(tag, @invalid_attrs)
      assert tag == Tags.get_tag!(tag.id)
    end

    test "delete_tag/1 deletes the tag", %{account: account} do
      tag = tag_fixture(account)
      assert {:ok, %Tag{}} = Tags.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> Tags.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset", %{account: account} do
      tag = tag_fixture(account)
      assert %Ecto.Changeset{} = Tags.change_tag(tag)
    end
  end
end
