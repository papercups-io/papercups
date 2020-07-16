defmodule ChatApiWeb.RegistrationControllerTest do
  use ChatApiWeb.ConnCase

  @password "secret1234"

  describe "create/2" do
    @valid_params %{
      "user" => %{
        "company_name" => "Papercups",
        "email" => "test@example.com",
        "password" => @password,
        "password_confirmation" => @password
      }
    }
    @invalid_params %{
      "user" => %{"email" => "invalid", "password" => @password, "password_confirmation" => "", "company_name" => "test"}
    }

    test "with valid params", %{conn: conn} do
      conn = post(conn, Routes.registration_path(conn, :create, @valid_params))

      assert json = json_response(conn, 200)
      assert json["data"]["token"]
      assert json["data"]["renew_token"]
    end

    test "with invalid params", %{conn: conn} do
      conn = post(conn, Routes.registration_path(conn, :create, @invalid_params))

      assert json = json_response(conn, 500)
      assert json["error"]["message"] == "Couldn't create user"
      assert json["error"]["status"] == 500
      assert json["error"]["errors"]["password_confirmation"] == ["does not match confirmation"]
      assert json["error"]["errors"]["email"] == ["has invalid format"]
    end
  end
end
