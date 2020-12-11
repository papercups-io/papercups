defmodule ChatApiWeb.NoteControllerTest do
  use ChatApiWeb.ConnCase

  import ChatApi.Factory
  alias ChatApi.Notes.Note

  @update_attrs %{
    body: "updated body!"
  }
  @invalid_attrs %{body: nil, customer_id: nil}

  setup %{conn: conn} do
    account = insert(:account)
    agent = insert(:user, account: account)
    customer = insert(:customer, account: account)
    note = insert(:note, body: "note body", account: account, author: agent, customer: customer)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, agent, [])

    {:ok,
     conn: conn,
     authed_conn: authed_conn,
     account: account,
     agent: agent,
     customer: customer,
     note: note}
  end

  describe "index" do
    test "lists all notes for the specified customer in the current account", %{
      authed_conn: authed_conn,
      note: note
    } do
      conn =
        get(authed_conn, Routes.note_path(authed_conn, :index), %{
          "note" => %{customer_id: note.customer_id}
        })

      note_ids = json_response(conn, 200)["data"] |> Enum.map(& &1["id"])

      assert note_ids == [note.id]
    end

    test "returns informative error when customer_id is missing from the request", %{
      authed_conn: authed_conn,
    } do
      conn = get(authed_conn, Routes.note_path(authed_conn, :index), %{
                   "note" => %{}
                 })
      assert json_response(conn, 400)["error"] == %{"status" => 400, "message" => "Please provide a customer_id"}
    end

    test "returns unauthorized when auth is invalid", %{conn: conn} do
      conn = get(conn, Routes.note_path(conn, :index))

      assert json_response(conn, 401)["errors"] != %{}
    end
  end

  describe "create note" do
    test "renders note when data is valid", %{
      authed_conn: authed_conn,
      customer: customer
    } do
      # note is valid
      note_params = %{body: "note body", customer_id: customer.id}
      conn = post(authed_conn, Routes.note_path(authed_conn, :create), note: note_params)

      assert %{
               "id" => created_id,
               "customer_id" => customer_id,
               "author_id" => agent_id
             } = json_response(conn, 201)["data"]

      # note is fetchable
      conn = get(authed_conn, Routes.note_path(authed_conn, :show, created_id))
      _fetched = json_response(conn, 200)["data"]

      assert _fetched = %{
               "id" => created_id,
               "object" => "note",
               "body" => "note body",
               "customer_id" => customer_id,
               "author_id" => agent_id
             }
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn = post(authed_conn, Routes.note_path(authed_conn, :create), note: @invalid_attrs)
      json = json_response(conn, 422)["errors"]
      assert json != %{}
    end
  end

  describe "update note" do
    test "renders note when data is valid", %{
      authed_conn: authed_conn,
      note: %Note{id: id} = note
    } do
      # update note
      conn = put(authed_conn, Routes.note_path(authed_conn, :update, note), note: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      # fetch updated note
      conn = get(authed_conn, Routes.note_path(conn, :show, id))

      assert %{
               "id" => _id,
               "body" => "updated body!"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, note: note} do
      conn = put(authed_conn, Routes.note_path(authed_conn, :update, note), note: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete note" do
    test "deletes chosen note", %{authed_conn: authed_conn, note: note} do
      # delete note
      conn = delete(authed_conn, Routes.note_path(authed_conn, :delete, note))
      assert response(conn, 204)

      # fetch note returns 404
      assert_error_sent 404, fn ->
        get(authed_conn, Routes.note_path(authed_conn, :show, note))
      end
    end
  end
end
