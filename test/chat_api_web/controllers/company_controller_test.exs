defmodule ChatApiWeb.CompanyControllerTest do
  use ChatApiWeb.ConnCase, async: true
  import ChatApi.Factory
  alias ChatApi.Companies.Company

  @update_attrs %{
    description: "some updated description",
    external_id: "some updated external_id",
    industry: "some updated industry",
    logo_image_url: "some updated logo_image_url",
    metadata: %{},
    name: "some updated name",
    slack_channel_id: "some updated slack_channel_id",
    slack_channel_name: "some updated slack_channel_name",
    website_url: "some updated website_url"
  }
  @invalid_attrs %{
    description: nil,
    external_id: nil,
    industry: nil,
    logo_image_url: nil,
    metadata: nil,
    name: nil,
    slack_channel_id: nil,
    slack_channel_name: nil,
    website_url: nil
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)
    company = insert(:company, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account, company: company}
  end

  describe "index" do
    test "lists all companies", %{authed_conn: authed_conn, company: company} do
      resp = get(authed_conn, Routes.company_path(authed_conn, :index))
      ids = json_response(resp, 200)["data"] |> Enum.map(& &1["id"])

      assert ids == [company.id]
    end
  end

  describe "show company" do
    test "shows company by id", %{
      account: account,
      authed_conn: authed_conn
    } do
      company =
        insert(:company, %{
          name: "Another company name",
          account: account
        })

      conn =
        get(
          authed_conn,
          Routes.company_path(authed_conn, :show, company.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's company", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a company
      another_account = insert(:account)

      company =
        insert(:company, %{
          name: "Another company name",
          account: another_account
        })

      # Using the original session, try to delete the new account's company
      conn =
        get(
          authed_conn,
          Routes.company_path(authed_conn, :show, company.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "create company" do
    test "renders company when data is valid", %{
      authed_conn: authed_conn,
      account: account
    } do
      resp =
        post(authed_conn, Routes.company_path(authed_conn, :create),
          company: params_for(:company, account: account, name: "Test Co")
        )

      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.company_path(authed_conn, :show, id))
      account_id = account.id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "object" => "company",
               "name" => "Test Co"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      conn = post(authed_conn, Routes.company_path(authed_conn, :create), company: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update company" do
    test "renders company when data is valid", %{
      authed_conn: authed_conn,
      company: %Company{id: id} = company
    } do
      conn =
        put(authed_conn, Routes.company_path(authed_conn, :update, company),
          company: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.company_path(authed_conn, :show, id))
      account_id = company.account_id

      assert %{
               "id" => ^id,
               "account_id" => ^account_id,
               "name" => "some updated name",
               "description" => "some updated description",
               "external_id" => "some updated external_id",
               "industry" => "some updated industry",
               "logo_image_url" => "some updated logo_image_url",
               "website_url" => "some updated website_url",
               "slack_channel_id" => "some updated slack_channel_id",
               "slack_channel_name" => "some updated slack_channel_name",
               "metadata" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, company: company} do
      conn =
        put(authed_conn, Routes.company_path(authed_conn, :update, company),
          company: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when editing another account's company",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a company
      another_account = insert(:account)

      company =
        insert(:company, %{
          name: "Another company name",
          account: another_account
        })

      # Using the original session, try to update the new account's company
      conn =
        put(
          authed_conn,
          Routes.company_path(authed_conn, :update, company),
          company: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete company" do
    test "deletes chosen company", %{authed_conn: authed_conn, company: company} do
      conn = delete(authed_conn, Routes.company_path(authed_conn, :delete, company))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.company_path(authed_conn, :show, company))
      end)
    end

    test "renders 404 when deleting another account's company",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a company
      another_account = insert(:account)

      company =
        insert(:company, %{
          name: "Another company name",
          account: another_account
        })

      # Using the original session, try to delete the new account's company
      conn =
        delete(
          authed_conn,
          Routes.company_path(authed_conn, :delete, company)
        )

      assert json_response(conn, 404)
    end
  end
end
