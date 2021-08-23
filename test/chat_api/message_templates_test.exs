defmodule ChatApi.MessageTemplatesTest do
  use ChatApi.DataCase, async: true

  import ChatApi.Factory
  alias ChatApi.MessageTemplates

  describe "companies" do
    alias ChatApi.MessageTemplates.MessageTemplate

    @update_attrs %{
      default_variable_values: %{},
      description: "some updated description",
      markdown: "some updated markdown",
      name: "some updated name",
      plain_text: "some updated plain_text",
      raw_html: "some updated raw_html",
      react_js: "some updated react_js",
      react_markdown: "some updated react_markdown",
      slack_markdown: "some updated slack_markdown",
      type: "some updated type"
    }
    @invalid_attrs %{
      name: nil,
      type: nil
    }

    setup do
      account = insert(:account)
      message_template = insert(:message_template, account: account)

      {:ok, account: account, message_template: message_template}
    end

    test "list_message_templates/1 returns all companies", %{
      account: account,
      message_template: message_template
    } do
      message_template_ids =
        MessageTemplates.list_message_templates(account.id)
        |> Enum.map(& &1.id)

      assert message_template_ids == [message_template.id]
    end

    test "get_message_template!/1 returns the message_template with given id", %{
      message_template: message_template
    } do
      found_message_template =
        MessageTemplates.get_message_template!(message_template.id)
        |> Repo.preload([:account])

      assert found_message_template == message_template
    end

    test "create_message_template/1 with valid data creates a message_template", %{
      account: account
    } do
      attrs = params_with_assocs(:message_template, account: account, name: "Test Template")

      assert {:ok, %MessageTemplate{name: "Test Template"}} =
               MessageTemplates.create_message_template(attrs)
    end

    test "create_message_template/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               MessageTemplates.create_message_template(@invalid_attrs)
    end

    test "update_message_template/2 with valid data updates the message_template", %{
      message_template: message_template
    } do
      assert {:ok, %MessageTemplate{} = message_template} =
               MessageTemplates.update_message_template(message_template, @update_attrs)

      assert message_template.description == "some updated description"
      assert message_template.markdown == "some updated markdown"
      assert message_template.name == "some updated name"
      assert message_template.plain_text == "some updated plain_text"
      assert message_template.raw_html == "some updated raw_html"
      assert message_template.react_js == "some updated react_js"
      assert message_template.react_markdown == "some updated react_markdown"
      assert message_template.slack_markdown == "some updated slack_markdown"
      assert message_template.type == "some updated type"
    end

    test "update_message_template/2 with invalid data returns error changeset", %{
      message_template: message_template
    } do
      assert {:error, %Ecto.Changeset{}} =
               MessageTemplates.update_message_template(message_template, @invalid_attrs)

      assert message_template ==
               MessageTemplates.get_message_template!(message_template.id)
               |> Repo.preload([:account])
    end

    test "delete_message_template/1 deletes the message_template", %{
      message_template: message_template
    } do
      assert {:ok, %MessageTemplate{}} =
               MessageTemplates.delete_message_template(message_template)

      assert_raise Ecto.NoResultsError, fn ->
        MessageTemplates.get_message_template!(message_template.id)
      end
    end

    test "change_message_template/1 returns a message_template changeset", %{
      message_template: message_template
    } do
      assert %Ecto.Changeset{} = MessageTemplates.change_message_template(message_template)
    end
  end
end
