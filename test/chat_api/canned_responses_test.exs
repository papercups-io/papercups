defmodule ChatApi.ChatApi.CannedResponsesTest do
  use ChatApi.DataCase

  import ChatApi.Factory

  alias ChatApi.CannedResponses

  describe "canned_responses" do
    alias ChatApi.CannedResponses.CannedResponse

    @update_attrs %{content: "some updated content", name: "some updated name"}
    @invalid_attrs %{content: nil, name: nil}

    setup do
      account = insert(:account)
      canned_response = insert(:canned_response, account: account)

      {:ok, canned_response: canned_response, account: account}
    end

    test "list_canned_responses/0 returns all canned_responses",
         %{canned_response: canned_response} do
      canned_response_list = CannedResponses.list_canned_responses()

      canned_response_ids = canned_response_list |> Enum.map(& &1.id)
      assert canned_response_ids == [canned_response.id]

      # we want accounts not to be preloaded
      canned_response_account_ids = canned_response_list |> Enum.map(& &1.account_id)
      assert canned_response_account_ids == [canned_response.account_id]
    end

    test "list_canned_responses_by_account/1 returns all canned_responses for a given account id",
         %{canned_response: canned_response, account: account} do
      assert CannedResponses.list_canned_responses_by_account(account.id) == [canned_response]

      # insert another canned_response with the same account and assert that we're getting both now
      insert(:canned_response, account: account, name: "another name")

      assert CannedResponses.list_canned_responses_by_account(account.id) |> length() == 2
    end

    test "get_canned_response!/1 returns the canned_response with given id",
         %{canned_response: canned_response, account: account} do
      canned_response_by_id = CannedResponses.get_canned_response!(canned_response.id)

      assert canned_response_by_id.id == canned_response.id
      assert canned_response_by_id.account_id == account.id
    end

    test "create_canned_response/1 with valid data creates a canned_response",
         %{canned_response: _canned_response, account: account} do
      assert {:ok, %CannedResponse{} = canned_response} =
               CannedResponses.create_canned_response(%{
                 content: "some content",
                 name: "some name",
                 account_id: account.id
               })

      assert canned_response.content == "some content"
      assert canned_response.name == "some name"

      assert CannedResponses.list_canned_responses_by_account(account.id) |> length() == 2
    end

    test "create_canned_response/1 with invalid data returns error changeset",
         %{canned_response: _canned_response} do
      assert {:error, %Ecto.Changeset{}} = CannedResponses.create_canned_response(@invalid_attrs)
    end

    test "create_canned_response/1 with duplicate name returns error changeset",
         %{canned_response: canned_response, account: account} do
      assert CannedResponses.list_canned_responses_by_account(account.id) == [
               canned_response
             ]

      assert {:error, %Ecto.Changeset{}} =
               CannedResponses.create_canned_response(%{
                 account_id: account.id,
                 name: canned_response.name,
                 content: "Other content"
               })

      assert CannedResponses.list_canned_responses_by_account(account.id) |> length() == 1
    end

    test "update_canned_response/2 with valid data updates the canned_response",
         %{canned_response: canned_response} do
      assert {:ok, %CannedResponse{} = canned_response} =
               CannedResponses.update_canned_response(canned_response, @update_attrs)

      assert canned_response.content == "some updated content"
      assert canned_response.name == "some updated name"
    end

    test "update_canned_response/2 with invalid data returns error changeset",
         %{canned_response: canned_response} do
      assert {:error, %Ecto.Changeset{}} =
               CannedResponses.update_canned_response(canned_response, @invalid_attrs)

      assert canned_response.id == CannedResponses.get_canned_response!(canned_response.id).id
    end

    test "update_canned_response/2 with duplicate name returns error changeset",
         %{canned_response: canned_response, account: account} do
      second_canned_response = insert(:canned_response, account: account, name: "another name")

      assert {:error, %Ecto.Changeset{}} =
               CannedResponses.update_canned_response(second_canned_response, %{
                 account_id: account.id,
                 name: canned_response.name,
                 content: "other content"
               })

      assert canned_response.id == CannedResponses.get_canned_response!(canned_response.id).id
    end

    test "delete_canned_response/1 deletes the canned_response",
         %{canned_response: canned_response} do
      assert {:ok, %CannedResponse{}} = CannedResponses.delete_canned_response(canned_response)

      assert_raise Ecto.NoResultsError, fn ->
        CannedResponses.get_canned_response!(canned_response.id)
      end
    end

    test "change_canned_response/1 returns a canned_response changeset",
         %{canned_response: canned_response} do
      assert %Ecto.Changeset{} = CannedResponses.change_canned_response(canned_response)
    end
  end
end
