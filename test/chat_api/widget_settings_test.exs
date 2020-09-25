defmodule ChatApi.WidgetSettingsTest do
  use ChatApi.DataCase, async: true

  alias ChatApi.WidgetSettings

  describe "widget_settings" do
    alias ChatApi.WidgetSettings.WidgetSetting

    def valid_attrs() do
      %{
        color: "some color",
        subtitle: "some subtitle",
        title: "some title"
      }
    end

    def update_attrs() do
      %{
        color: "some updated color",
        subtitle: "some updated subtitle",
        title: "some updated title"
      }
    end

    @valid_metadata %{"host" => "app.papercups.io", "pathname" => "/"}

    setup do
      account = account_fixture()
      setting = widget_settings_fixture(account)

      {:ok, setting: setting, account: account}
    end

    test "list_widget_settings/0 returns all widget_settings", %{setting: widget_setting} do
      widget_ids = WidgetSettings.list_widget_settings() |> Enum.map(& &1.id)
      assert widget_ids == [widget_setting.id]
    end

    test "get_widget_setting!/1 returns the widget_setting with given id", %{
      setting: widget_setting
    } do
      fetched_widget = WidgetSettings.get_widget_setting!(widget_setting.id)

      assert fetched_widget.id == widget_setting.id
      assert fetched_widget.account_id == widget_setting.account_id
    end

    test "update_widget_setting/2 with valid data updates the widget_setting", %{
      setting: widget_setting
    } do
      assert {:ok, %WidgetSetting{} = widget_setting} =
               WidgetSettings.update_widget_setting(widget_setting, update_attrs())

      assert widget_setting.color == "some updated color"
      assert widget_setting.subtitle == "some updated subtitle"
      assert widget_setting.title == "some updated title"
    end

    test "update_widget_metadata/2 with valid data updates the metadata if no settings exist yet",
         %{account: account} do
      assert {:ok, %WidgetSetting{} = widget_setting} =
               WidgetSettings.update_widget_metadata(account.id, @valid_metadata)

      assert widget_setting.host == "app.papercups.io"
      assert widget_setting.pathname == "/"
    end

    test "delete_widget_setting/1 deletes the widget_setting", %{setting: widget_setting} do
      assert {:ok, %WidgetSetting{}} = WidgetSettings.delete_widget_setting(widget_setting)

      assert_raise Ecto.NoResultsError, fn ->
        WidgetSettings.get_widget_setting!(widget_setting.id)
      end
    end

    test "change_widget_setting/1 returns a widget_setting changeset", %{setting: widget_setting} do
      assert %Ecto.Changeset{} = WidgetSettings.change_widget_setting(widget_setting)
    end
  end
end
