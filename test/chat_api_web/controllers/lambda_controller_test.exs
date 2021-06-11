defmodule ChatApiWeb.LambdaControllerTest do
  use ChatApiWeb.ConnCase
  import ChatApi.Factory
  alias ChatApi.Lambdas.Lambda

  @create_attrs %{
    code: "some code",
    description: "some description",
    language: "javascript",
    last_deployed_at: "2010-04-17T14:00:00Z",
    last_executed_at: "2010-04-17T14:00:00Z",
    metadata: %{},
    name: "some name",
    runtime: "nodejs14.x",
    status: "pending"
  }
  @update_attrs %{
    code: "some updated code",
    description: "some updated description",
    language: "javascript",
    last_deployed_at: "2011-05-18T15:01:01Z",
    last_executed_at: "2011-05-18T15:01:01Z",
    metadata: %{},
    name: "some updated name",
    runtime: "nodejs14.x",
    status: "active"
  }
  @invalid_attrs %{
    code: nil,
    description: nil,
    language: nil,
    last_deployed_at: nil,
    last_executed_at: nil,
    metadata: nil,
    name: nil,
    runtime: nil,
    status: nil
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "index" do
    test "lists all lambdas", %{authed_conn: authed_conn} do
      resp = get(authed_conn, Routes.lambda_path(authed_conn, :index))
      assert json_response(resp, 200)["data"] == []
    end
  end

  describe "create lambda" do
    test "renders lambda when data is valid", %{authed_conn: authed_conn} do
      resp = post(authed_conn, Routes.lambda_path(authed_conn, :create), lambda: @create_attrs)
      assert %{"id" => id} = json_response(resp, 201)["data"]

      resp = get(authed_conn, Routes.lambda_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "object" => "lambda",
               "name" => "some name"
             } = json_response(resp, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn} do
      resp = post(authed_conn, Routes.lambda_path(authed_conn, :create), lambda: @invalid_attrs)
      assert json_response(resp, 422)["errors"] != %{}
    end
  end

  describe "show lambda" do
    setup [:create_lambda]

    test "shows lambda by id", %{
      authed_conn: authed_conn,
      lambda: lambda
    } do
      conn =
        get(
          authed_conn,
          Routes.lambda_path(authed_conn, :show, lambda.id)
        )

      assert json_response(conn, 200)["data"]
    end

    test "renders 404 when asking for another user's lambda", %{
      authed_conn: authed_conn
    } do
      # Create a new account and give it a lambda
      another_account = insert(:account)

      another_lambda =
        insert(:lambda, %{
          name: "Another lambda name",
          account: another_account
        })

      # Using the original session, try to delete the new account's lambda
      conn =
        get(
          authed_conn,
          Routes.lambda_path(authed_conn, :show, another_lambda.id)
        )

      assert json_response(conn, 404)
    end
  end

  describe "update lambda" do
    setup [:create_lambda]

    test "renders lambda when data is valid", %{
      authed_conn: authed_conn,
      lambda: %Lambda{id: id} = lambda
    } do
      conn =
        put(authed_conn, Routes.lambda_path(authed_conn, :update, lambda), lambda: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(authed_conn, Routes.lambda_path(authed_conn, :show, id))

      assert %{
               "id" => _id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{authed_conn: authed_conn, lambda: lambda} do
      conn =
        put(authed_conn, Routes.lambda_path(authed_conn, :update, lambda), lambda: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders 404 when updating another account's lambda",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a lambda
      another_account = insert(:account)

      another_lambda =
        insert(:lambda, %{
          name: "Another lambda name",
          account: another_account
        })

      # Using the original session, try to update the new account's lambda
      conn =
        put(
          authed_conn,
          Routes.lambda_path(authed_conn, :update, another_lambda),
          lambda: @update_attrs
        )

      assert json_response(conn, 404)
    end
  end

  describe "delete lambda" do
    setup [:create_lambda]

    test "deletes chosen lambda", %{authed_conn: authed_conn, lambda: lambda} do
      conn = delete(authed_conn, Routes.lambda_path(authed_conn, :delete, lambda))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(authed_conn, Routes.lambda_path(authed_conn, :show, lambda))
      end)
    end

    test "renders 404 when deleting another account's lambda",
         %{authed_conn: authed_conn} do
      # Create a new account and give it a lambda
      another_account = insert(:account)

      lambda =
        insert(:lambda, %{
          name: "Another lambda name",
          account: another_account
        })

      # Using the original session, try to delete the new account's lambda
      conn = delete(authed_conn, Routes.lambda_path(authed_conn, :delete, lambda))

      assert json_response(conn, 404)
    end
  end

  defp create_lambda(%{account: account}) do
    lambda = insert(:lambda, account: account)

    %{lambda: lambda}
  end
end
