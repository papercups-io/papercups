defmodule ChatApi.CannedResponsesTest do
  use ChatApi.DataCase

  import ChatApi.Factory

  alias ChatApi.CannedResponses

  describe "canned_responses" do
    alias ChatApi.CannedResponses.CannedResponse

    @valid_attrs %{content: "some content", name: "some name"}
    @update_attrs %{content: "some updated content", name: "some updated name"}
    @invalid_attrs %{content: nil, name: nil}

    setup do
      account = insert(:account)
      canned_response = insert(:canned_response, account: account)

      {:ok, account: account, canned_response: canned_response}
    end

    test "list_canned_responses/1 returns all canned_responses", %{
      account: account,
      canned_response: canned_response
    } do
      canned_response_ids = CannedResponses.list_canned_responses(account.id) |> Enum.map(& &1.id)
      assert canned_response_ids == [canned_response.id]
    end

    test "get_canned_response!/1 returns the canned_response with given id", %{
      canned_response: canned_response
    } do
      assert canned_response ==
               CannedResponses.get_canned_response!(canned_response.id)
               |> Repo.preload([:account])
    end

    test "create_canned_response/1 with valid data creates a canned_response" do
      assert {:ok, %CannedResponse{} = canned_response} =
               CannedResponses.create_canned_response(
                 params_with_assocs(:canned_response, @valid_attrs)
               )

      assert canned_response.content == "some content"
      assert canned_response.name == "some name"
    end

    test "create_canned_response/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CannedResponses.create_canned_response(@invalid_attrs)
    end

    test "update_canned_response/2 with valid data updates the canned_response", %{
      canned_response: canned_response
    } do
      assert {:ok, %CannedResponse{} = canned_response} =
               CannedResponses.update_canned_response(canned_response, @update_attrs)

      assert canned_response.content == "some updated content"
      assert canned_response.name == "some updated name"
    end

    test "update_canned_response/2 with invalid data returns error changeset", %{
      canned_response: canned_response
    } do
      assert {:error, %Ecto.Changeset{}} =
               CannedResponses.update_canned_response(canned_response, @invalid_attrs)

      assert canned_response ==
               CannedResponses.get_canned_response!(canned_response.id)
               |> Repo.preload([:account])
    end

    test "delete_canned_response/1 deletes the canned_response", %{
      canned_response: canned_response
    } do
      assert {:ok, %CannedResponse{}} = CannedResponses.delete_canned_response(canned_response)

      assert_raise Ecto.NoResultsError, fn ->
        CannedResponses.get_canned_response!(canned_response.id)
      end
    end

    test "change_canned_response/1 returns a canned_response changeset", %{
      canned_response: canned_response
    } do
      assert %Ecto.Changeset{} = CannedResponses.change_canned_response(canned_response)
    end
  end
end
