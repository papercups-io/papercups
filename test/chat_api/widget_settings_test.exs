defmodule ChatApi.WidgetSettingsTest do
  use ChatApi.DataCase

  alias ChatApi.WidgetSettings
  alias ChatApi.Accounts

  describe "widget_settings" do
    alias ChatApi.WidgetSettings.WidgetSetting

    def valid_attrs() do
      {:ok, account} = Accounts.create_account(%{company_name: "Taro"})

      %{
        color: "some color",
        subtitle: "some subtitle",
        title: "some title",
        account_id: account.id
      }
    end

    def update_attrs() do
      {:ok, account} = Accounts.create_account(%{company_name: "Taro"})

      %{
        color: "some updated color",
        subtitle: "some updated subtitle",
        title: "some updated title",
        account_id: account.id
      }
    end

    @invalid_attrs %{color: nil, subtitle: nil, title: nil}
    @valid_metadata %{"host" => "app.papercups.io", "pathname" => "/"}

    def fixture(:account) do
      {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
      account
    end

    def widget_settings_fixture(attrs \\ %{}) do
      {:ok, widget_setting} =
        attrs
        |> Enum.into(valid_attrs())
        |> WidgetSettings.create_widget_setting()

      widget_setting
    end

    test "list_widget_settings/0 returns all widget_settings" do
      widget_setting = widget_settings_fixture()
      assert WidgetSettings.list_widget_settings() == [widget_setting]
    end

    test "get_widget_setting!/1 returns the widget_setting with given id" do
      widget_setting = widget_settings_fixture()
      assert WidgetSettings.get_widget_setting!(widget_setting.id) == widget_setting
    end

    test "create_widget_setting/1 with valid data creates a widget_setting" do
      assert {:ok, %WidgetSetting{} = widget_setting} =
               WidgetSettings.create_widget_setting(valid_attrs())

      assert widget_setting.color == "some color"
      assert widget_setting.subtitle == "some subtitle"
      assert widget_setting.title == "some title"
    end

    test "create_widget_setting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = WidgetSettings.create_widget_setting(@invalid_attrs)
    end

    test "update_widget_setting/2 with valid data updates the widget_setting" do
      widget_setting = widget_settings_fixture()

      assert {:ok, %WidgetSetting{} = widget_setting} =
               WidgetSettings.update_widget_setting(widget_setting, update_attrs())

      assert widget_setting.color == "some updated color"
      assert widget_setting.subtitle == "some updated subtitle"
      assert widget_setting.title == "some updated title"
    end

    test "update_widget_metadata/2 with valid data updates the metadata if no settings exist yet" do
      account = fixture(:account)

      assert {:ok, %WidgetSetting{} = widget_setting} =
               WidgetSettings.update_widget_metadata(account.id, @valid_metadata)

      assert widget_setting.host == "app.papercups.io"
      assert widget_setting.pathname == "/"
    end

    test "delete_widget_setting/1 deletes the widget_setting" do
      widget_setting = widget_settings_fixture()
      assert {:ok, %WidgetSetting{}} = WidgetSettings.delete_widget_setting(widget_setting)

      assert_raise Ecto.NoResultsError, fn ->
        WidgetSettings.get_widget_setting!(widget_setting.id)
      end
    end

    test "change_widget_setting/1 returns a widget_setting changeset" do
      widget_setting = widget_settings_fixture()
      assert %Ecto.Changeset{} = WidgetSettings.change_widget_setting(widget_setting)
    end
  end
end
