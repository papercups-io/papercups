defmodule ChatApi.LambdasTest do
  use ChatApi.DataCase
  import ChatApi.Factory
  alias ChatApi.Lambdas

  describe "lambdas" do
    alias ChatApi.Lambdas.Lambda

    @valid_attrs %{
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

    setup do
      account = insert(:account)
      lambda = insert(:lambda, account: account)

      {:ok, account: account, lambda: lambda}
    end

    test "list_lambdas/1 returns all lambdas for the given account", %{
      account: account,
      lambda: lambda
    } do
      lambda_ids = Lambdas.list_lambdas(account.id) |> Enum.map(& &1.id)

      assert lambda_ids == [lambda.id]
    end

    test "get_lambda!/1 returns the lambda with given id", %{lambda: lambda} do
      result = Lambdas.get_lambda!(lambda.id)

      assert lambda.id == result.id
      assert lambda.name == result.name
      assert lambda.description == result.description
      assert lambda.code == result.code
      assert lambda.status == result.status
    end

    test "create_lambda/1 with valid data creates a lambda" do
      assert {:ok, %Lambda{} = lambda} =
               Lambdas.create_lambda(params_with_assocs(:lambda, Map.to_list(@valid_attrs)))

      assert lambda.name == "some name"
      assert lambda.description == "some description"
      assert lambda.code == "some code"
      assert lambda.language == "javascript"
      assert lambda.last_deployed_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert lambda.last_executed_at == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert lambda.metadata == %{}
      assert lambda.runtime == "nodejs14.x"
      assert lambda.status == "pending"
    end

    test "create_lambda/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Lambdas.create_lambda(@invalid_attrs)
    end

    test "update_lambda/2 with valid data updates the lambda", %{lambda: lambda} do
      assert {:ok, %Lambda{} = lambda} = Lambdas.update_lambda(lambda, @update_attrs)
      assert lambda.code == "some updated code"
      assert lambda.description == "some updated description"
      assert lambda.language == "javascript"
      assert lambda.last_deployed_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert lambda.last_executed_at == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert lambda.metadata == %{}
      assert lambda.name == "some updated name"
      assert lambda.runtime == "nodejs14.x"
      assert lambda.status == "active"
    end

    test "update_lambda/2 with invalid data returns error changeset", %{lambda: lambda} do
      assert {:error, %Ecto.Changeset{}} = Lambdas.update_lambda(lambda, @invalid_attrs)

      current = Lambdas.get_lambda!(lambda.id)

      assert lambda.id == current.id
      assert lambda.name == current.name
      assert lambda.description == current.description
      assert lambda.code == current.code
    end

    test "delete_lambda/1 deletes the lambda", %{lambda: lambda} do
      assert {:ok, %Lambda{}} = Lambdas.delete_lambda(lambda)
      assert_raise Ecto.NoResultsError, fn -> Lambdas.get_lambda!(lambda.id) end
    end

    test "change_lambda/1 returns a lambda changeset", %{lambda: lambda} do
      assert %Ecto.Changeset{} = Lambdas.change_lambda(lambda)
    end
  end
end
