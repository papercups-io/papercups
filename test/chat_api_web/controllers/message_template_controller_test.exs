defmodule ChatApiWeb.MessageTemplateControllerTest do
  use ChatApiWeb.ConnCase, async: true
  import ChatApi.Factory
  alias ChatApi.MessageTemplates.MessageTemplate

  @update_attrs %{
    default_variable_values: %{},
    description: "some updated description",
    markdown: "some updated markdown",
    name: "some updated name",
    plain_text: "some updated plain_text",
    raw_html: "some updated raw_html",
    react_js: "some updated react_js",
    react_markdown: "some updated react_markdown",
    slack_markdown: "some updated slack_markdown",
    type: "some updated type"
  }
  @invalid_attrs %{
    name: nil,
    type: nil
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    message_template = insert(:message_template, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok,
     conn: conn, authed_conn: authed_conn, account: account, message_template: message_template}
  end

  describe "index" do
    test "lists all message_templates", %{
      authed_conn: authed_conn,
      message_template: message_template
    } do
      resp = get(authed_conn, Routes.message_template_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [message_template.id]
    end
  end

  describe "show message_template" do
    test "shows message_template by id", %{
      account: account,
      authed_conn: authed_conn
    } do
      message_template =
        insert(:message_template, %{
          name: "Another message_template name",
          account: account
        })

      conn =
        get(
          authed_conn,
          Routes.message_template_path(authed_conn, :show, message_template.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's message_template", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a message_template
      another_account = insert(:account)

      message_template =
        insert(:message_template, %{
          name: "Another message_template name",
          account: another_account
        })

      # Using the original session, try to delete the new account's message_template
      conn =
        get(
          authed_conn,
          Routes.message_template_path(authed_conn, :show, message_template.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "create message_template" do
    test "renders message_template when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      resp =
        post(authed_conn, Routes.message_template_path(authed_conn, :create),
          message_template: params_for(:message_template, account: account, name: "Test Template")
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.message_template_path(authed_conn, :show, id))
      account_id = account.id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "message_template",
               "name" => "Test Template"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn =
        post(authed_conn, Routes.message_template_path(authed_conn, :create),
          message_template: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update message_template" do
    test "renders message_template when data is valid", %{
      authed_conn: authed_conn,
      message_template: %MessageTemplate{id: id} = message_template
    } do
      conn =
        put(authed_conn, Routes.message_template_path(authed_conn, :update, message_template),
          message_template: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.message_template_path(authed_conn, :show, id))
      account_id = message_template.account_id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "name" => "some updated name",
               "type" => "some updated type",
               "description" => "some updated description",
               "markdown" => "some updated markdown",
               "plain_text" => "some updated plain_text",
               "raw_html" => "some updated raw_html",
               "react_js" => "some updated react_js",
               "react_markdown" => "some updated react_markdown",
               "slack_markdown" => "some updated slack_markdown",
               "default_variable_values" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      authed_conn: authed_conn,
      message_template: message_template
    } do
      conn =
        put(authed_conn, Routes.message_template_path(authed_conn, :update, message_template),
          message_template: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when editing another account's message_template",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a message_template
      another_account = insert(:account)

      message_template =
        insert(:message_template, %{
          name: "Another message_template name",
          account: another_account
        })

      # Using the original session, try to update the new account's message_template
      conn =
        put(
          authed_conn,
          Routes.message_template_path(authed_conn, :update, message_template),
          message_template: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete message_template" do
    test "deletes chosen message_template", %{
      authed_conn: authed_conn,
      message_template: message_template
    } do
      conn =
        delete(authed_conn, Routes.message_template_path(authed_conn, :delete, message_template))

      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.message_template_path(authed_conn, :show, message_template))
      end)
    end

    test "renders 404 when deleting another account's message_template",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a message_template
      another_account = insert(:account)

      message_template =
        insert(:message_template, %{
          name: "Another message_template name",
          account: another_account
        })

      # Using the original session, try to delete the new account's message_template
      conn =
        delete(
          authed_conn,
          Routes.message_template_path(authed_conn, :delete, message_template)
        )

      assert json_response(conn, 404)
    end
  end
end
