defmodule ChatApi.WidgetConfigsTest do
  use ChatApi.DataCase

  alias ChatApi.WidgetConfigs
  alias ChatApi.Accounts

  describe "widget_configs" do
    alias ChatApi.WidgetConfigs.WidgetConfig

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

    def fixture(:account) do
      {:ok, account} = Accounts.create_account(%{company_name: "Taro"})
      account
    end

    def widget_config_fixture(attrs \\ %{}) do
      {:ok, widget_config} =
        attrs
        |> Enum.into(valid_attrs())
        |> WidgetConfigs.create_widget_config()

      widget_config
    end

    test "list_widget_configs/0 returns all widget_configs" do
      widget_config = widget_config_fixture()
      assert WidgetConfigs.list_widget_configs() == [widget_config]
    end

    test "get_widget_config!/1 returns the widget_config with given id" do
      widget_config = widget_config_fixture()
      assert WidgetConfigs.get_widget_config!(widget_config.id) == widget_config
    end

    test "create_widget_config/1 with valid data creates a widget_config" do
      assert {:ok, %WidgetConfig{} = widget_config} =
               WidgetConfigs.create_widget_config(valid_attrs())

      assert widget_config.color == "some color"
      assert widget_config.subtitle == "some subtitle"
      assert widget_config.title == "some title"
    end

    test "create_widget_config/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = WidgetConfigs.create_widget_config(@invalid_attrs)
    end

    test "update_widget_config/2 with valid data updates the widget_config" do
      widget_config = widget_config_fixture()

      assert {:ok, %WidgetConfig{} = widget_config} =
               WidgetConfigs.update_widget_config(widget_config, update_attrs())

      assert widget_config.color == "some updated color"
      assert widget_config.subtitle == "some updated subtitle"
      assert widget_config.title == "some updated title"
    end

    test "update_widget_config/2 with invalid data returns error changeset" do
      widget_config = widget_config_fixture()

      assert {:error, %Ecto.Changeset{}} =
               WidgetConfigs.update_widget_config(widget_config, @invalid_attrs)

      assert widget_config == WidgetConfigs.get_widget_config!(widget_config.id)
    end

    test "delete_widget_config/1 deletes the widget_config" do
      widget_config = widget_config_fixture()
      assert {:ok, %WidgetConfig{}} = WidgetConfigs.delete_widget_config(widget_config)

      assert_raise Ecto.NoResultsError, fn ->
        WidgetConfigs.get_widget_config!(widget_config.id)
      end
    end

    test "change_widget_config/1 returns a widget_config changeset" do
      widget_config = widget_config_fixture()
      assert %Ecto.Changeset{} = WidgetConfigs.change_widget_config(widget_config)
    end
  end
end
