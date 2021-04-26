defmodule ChatApi.NotesTest do
  use ChatApi.DataCase

  import ChatApi.Factory
  alias ChatApi.Notes
  alias Ecto.UUID

  describe "notes" do
    alias ChatApi.Notes.Note

    @update_attrs %{body: "some updated body"}
    @invalid_attrs %{body: nil}

    setup do
      account = insert(:account)
      agent = insert(:user, account: account)
      customer = insert(:customer, account: account)
      note = insert(:note, body: "note_body", account: account, author: agent, customer: customer)

      {:ok, agent: agent, account: account, customer: customer, note: note}
    end

    test "list_notes_by_account/2 returns all notes for the given account and customer", %{
      note: note,
      account: account,
      customer: customer
    } do
      note_ids =
        Notes.list_notes_by_account(account.id, %{"customer_id" => customer.id})
        |> Enum.map(& &1.id)

      assert note_ids == [note.id]
    end

    test "list_notes_by_account/2 returns an empty list if none are found", %{
      account: account
    } do
      note_ids =
        Notes.list_notes_by_account(account.id, %{"customer_id" => UUID.generate()})
        |> Enum.map(& &1.id)

      assert note_ids == []
    end

    test "get_note!/1 returns the note with given id", %{note: note} do
      found = Notes.get_note!(note.id)
      assert found.id == note.id
      assert found.body == note.body
    end

    test "create_note/1 with valid data creates a note", %{
      account: account,
      customer: customer,
      agent: agent
    } do
      assert {:ok, %Note{} = note} =
               Notes.create_note(%{
                 body: "some body",
                 account_id: account.id,
                 customer_id: customer.id,
                 author_id: agent.id
               })

      assert note.body == "some body"
      assert note.customer_id == customer.id
      assert note.author_id == agent.id
      assert note.account_id == account.id
    end

    test "create_note/1 with empty body returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(%{body: ""})
    end

    test "create_note/1 with nil body returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note", %{note: note} do
      assert {:ok, %Note{} = note} = Notes.update_note(note, @update_attrs)
      assert note.body == "some updated body"
    end

    test "update_note/2 with invalid data returns error changeset", %{note: note} do
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(note, @invalid_attrs)
      found = Notes.get_note!(note.id)
      assert found.id == note.id
      assert found.updated_at == note.updated_at
    end

    test "delete_note/1 deletes the note", %{note: note} do
      assert {:ok, %Note{}} = Notes.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset", %{note: note} do
      assert %Ecto.Changeset{} = Notes.change_note(note)
    end
  end
end
