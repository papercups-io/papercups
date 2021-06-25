defmodule ChatApi.AwsTest do
  use ChatApi.DataCase

  alias ChatApi.Aws

  describe "aws" do
    test "validate_config/0 validates that all the environment variables are set" do
      # Not sure the best way to test environment variables...
      validation =
        case Aws.Config.validate() do
          {:ok,
           %{
             aws_key_id: _aws_key_id,
             aws_secret_key: _aws_secret_key,
             bucket_name: _bucket_name,
             region: _region
           }} ->
            true

          {:error, :invalid_aws_config, _} ->
            true

          _ ->
            false
        end

      assert validation
    end

    test "generate_unique_filename/1 generates a unique filename with a uuid" do
      filename = "test-file.jpg"
      uniq_1 = Aws.generate_unique_filename(filename)
      uniq_2 = Aws.generate_unique_filename(filename)

      assert uniq_1 != uniq_2
    end

    test "generate_unique_filename/1 replaces spaces with dashes if necessary" do
      filename = "test file.jpg"
      assert Aws.generate_unique_filename(filename) =~ "-test-file.jpg"
    end

    test "get_file_url/2 formats the s3 file url" do
      filename = "test-file.jpg"
      bucket = "papercups"

      assert Aws.get_file_url(filename, bucket) ==
               "https://papercups.s3.amazonaws.com/test-file.jpg"
    end
  end

  describe "lambda" do
    @moduletag :lambda_development

    test "get_lambda_function" do
      function_name = "test"
      %{"Configuration" => configuration} = Aws.get_lambda_function(function_name)
      assert configuration["FunctionName"] == function_name
    end

    # test "create" do
    #   %{"FunctionName" => function_name} =
    #     Aws.create_function_by_file(
    #       Path.absname("test/assets/test.zip"),
    #       Aws.generate_unique_filename("test_function_name"),
    #       "test/index.handler"
    #     )

    #   %{"Configuration" => configuration} = Aws.get_lambda_function(function_name)
    #   assert function_name == configuration["FunctionName"]
    #   Aws.invoke_lambda_function(function_name, %{"test" => "test"})

    #   Aws.delete_lambda_function(function_name)
    # end

    test "creating and updating a function" do
      api_key = "33652476496653383581"

      code = """
      exports.handler = async (event) => {
        return {statusCode: 200, body: JSON.stringify(event)};
      };

      """

      function_name = Aws.generate_unique_filename("test_function_name")

      %{"FunctionName" => ^function_name} =
        Aws.create_function_by_code(code, function_name, %{
          "env" => %{"PAPERCUPS_API_KEY" => api_key}
        })

      %{"body" => body, "statusCode" => status_code} =
        Aws.invoke_lambda_function(function_name, %{"hello" => "world"})

      assert body =~ "hello"
      assert body =~ "world"
      assert status_code == 200

      updated_code = """
      exports.handler = async (event) => {
        return {statusCode: 200, body: JSON.stringify({"updated": "function"})};
      };
      """

      %{"FunctionName" => ^function_name} =
        Aws.update_function_by_code(updated_code, function_name)

      %{"body" => body, "statusCode" => status_code} =
        Aws.invoke_lambda_function(function_name, %{"hello" => "world"})

      assert body =~ "updated"
      assert body =~ "function"
      assert status_code == 200

      Aws.delete_lambda_function(function_name)
    end

    test "creating and updating a function with environment variables" do
      api_key = "33652476496653383581"
      function_name = Aws.generate_unique_filename("test_function_name")

      code = """
      exports.handler = async (event) => {
        return {statusCode: 200, body: JSON.stringify(process.env.PAPERCUPS_API_KEY)};
      };
      """

      %{"FunctionName" => ^function_name} =
        Aws.create_function_by_code(code, function_name, %{
          "env" => %{"PAPERCUPS_API_KEY" => api_key}
        })

      %{"body" => body} = Aws.invoke_lambda_function(function_name, %{"hello" => "world"})
      assert body =~ api_key

      new_api_key = "NEW_API_KEY"

      Aws.update_function_configuration(function_name, %{
        "env" => %{"PAPERCUPS_API_KEY" => new_api_key}
      })

      %{"body" => body} = Aws.invoke_lambda_function(function_name, %{"hello" => "world"})
      assert body =~ new_api_key

      Aws.delete_lambda_function(function_name)
    end

    test "invoke_lambda_function" do
      function_name = Aws.generate_unique_filename("test_function_name")

      code = """
      exports.handler = async (event) => {
        return {statusCode: 200, body: event};
      };
      """

      Aws.create_function_by_code(code, function_name)

      %{"statusCode" => 200, "body" => body} =
        Aws.invoke_lambda_function(function_name, %{"hello" => "world"})

      assert body["hello"] == "world"
    end

    test "delete" do
      function_name = Aws.generate_unique_filename("test_function_name")

      code = """
      exports.handler = async (event) => {
        return {statusCode: 200, body: event};
      };
      """

      Aws.create_function_by_code(code, function_name)
      assert Aws.get_lambda_function(function_name)
      Aws.delete_lambda_function(function_name)

      assert_raise ExAws.Error, ~r/Function not found/, fn ->
        Aws.get_lambda_function(function_name)
      end
    end
  end
end
