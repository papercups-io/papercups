defmodule ChatApi.AwsTest do
  use ChatApi.DataCase

  alias ChatApi.Aws

  describe "aws" do
    test "validate_config/0 validates that all the environment variables are set" do
      assert {:error, [aws_key_id: "", aws_secret_key: "", bucket_name: "", region: ""]} =
               Aws.validate_config()
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
               "https://papercups.s3.amazonaws.com/papercups/test-file.jpg"
    end
  end
end
