defmodule ChatApiWeb.UploadControllerTest do
  use ChatApiWeb.ConnCase
  import Mock
  import ChatApi.Factory

  @config %{
    aws_key_id: "aws_key_id",
    aws_secret_key: "aws_secret_key",
    bucket_name: "bucket_name",
    region: "region"
  }

  setup %{conn: conn} do
    account = insert(:account)
    user = insert(:user, account: account)

    conn = put_req_header(conn, "accept", "application/json")
    authed_conn = Pow.Plug.assign_current_user(conn, user, [])

    {:ok, conn: conn, authed_conn: authed_conn, account: account}
  end

  describe "create upload" do
    test "it successfully creates a file", %{conn: conn, account: account} do
      file = %Plug.Upload{filename: "Test File", content_type: "image/jpg", path: "/path/to/file"}

      with_mocks([
        {ChatApi.Aws, [:passthrough], upload: fn _, _ -> {:ok, %{}} end},
        {ChatApi.Aws.Config, [:passthrough], validate: fn -> {:ok, @config} end}
      ]) do
        resp = post(conn, Routes.upload_path(conn, :create), file: file, account_id: account.id)

        assert %{
                 "content_type" => "image/jpg",
                 "file_url" => url,
                 "filename" => "Test-File",
                 "object" => "file"
               } = json_response(resp, 201)["data"]

        assert url =~ "Test-File"
      end
    end

    test "it fails if AWS keys are not set", %{conn: conn, account: account} do
      file = %Plug.Upload{filename: "Test File", content_type: "image/jpg", path: "/path/to/file"}

      with_mock ChatApi.Aws.Config,
                [:passthrough],
                validate: fn ->
                  {:error, :invalid_aws_config, [aws_key_id: "", bucket_name: ""]}
                end do
        resp = post(conn, Routes.upload_path(conn, :create), file: file, account_id: account.id)

        assert json_response(resp, 401)["error"]["message"] =~ "Missing AWS keys"
      end
    end

    test "it fails if File.read errors", %{conn: conn, account: account} do
      file = %Plug.Upload{filename: "Test File", content_type: "image/jpg", path: "/path/to/file"}

      with_mock ChatApi.Aws.Config,
                [:passthrough],
                validate: fn ->
                  {:ok, @config}
                end do
        resp = post(conn, Routes.upload_path(conn, :create), file: file, account_id: account.id)

        assert json_response(resp, 422)["error"]["message"] =~ "Invalid or malformed file"
      end
    end
  end
end
