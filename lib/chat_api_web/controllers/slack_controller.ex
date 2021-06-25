defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  require Logger
  alias ChatApiWeb.SlackAuthorizationView
  alias ChatApi.{Conversations, Slack, SlackAuthorizations}
  alias ChatApi.SlackAuthorizations.SlackAuthorization

  action_fallback(ChatApiWeb.FallbackController)

  @spec notify(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def notify(conn, %{"text" => text} = params) do
    with %{account_id: account_id} <- conn.assigns.current_user,
         %SlackAuthorization{access_token: access_token, channel: channel} <-
           SlackAuthorizations.get_authorization_by_account(account_id, %{
             type: Map.get(params, "type", "reply")
           }),
         {:ok, %{body: data}} <-
           Slack.Client.send_message(
             %{
               "channel" => Map.get(params, "channel", channel),
               "text" => text
             },
             access_token
           ) do
      json(conn, %{data: data})
    else
      _ -> json(conn, %{data: nil})
    end
  end

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code} = params) do
    Logger.info("Code from Slack OAuth: #{inspect(code)}")

    # TODO: improve error handling?
    with %{account_id: account_id, email: email} <- conn.assigns.current_user,
         redirect_uri <- Map.get(params, "redirect_url"),
         {:ok, response} <- Slack.Client.get_access_token(code, redirect_uri),
         :ok <- Logger.info("Slack OAuth response: #{inspect(response)}"),
         %{body: body} <- response,
         %{
           "access_token" => access_token,
           "app_id" => app_id,
           "bot_user_id" => bot_user_id,
           "scope" => scope,
           "token_type" => token_type,
           "authed_user" => authed_user,
           "team" => team,
           "incoming_webhook" => incoming_webhook
         } <- body,
         %{"id" => authed_user_id} <- authed_user,
         %{"id" => team_id, "name" => team_name} <- team,
         # TODO: validate that `channel_id` doesn't match account integration with different `type`
         %{
           "channel" => channel,
           "channel_id" => channel_id,
           "configuration_url" => configuration_url,
           "url" => webhook_url
         } <- incoming_webhook,
         integration_type <- Map.get(params, "type", "reply"),
         :ok <-
           Slack.Validation.validate_authorization_channel_id(
             channel_id,
             account_id,
             integration_type
           ) do
      # TODO: after creating, check if connected channel is private;
      # If yes, use webhook_url to send notification that Papercups app needs
      # to be added manually, along with instructions for how to do so
      SlackAuthorizations.create_or_update(account_id, %{
        account_id: account_id,
        access_token: access_token,
        app_id: app_id,
        authed_user_id: authed_user_id,
        bot_user_id: bot_user_id,
        scope: scope,
        token_type: token_type,
        channel: channel,
        channel_id: channel_id,
        configuration_url: configuration_url,
        team_id: team_id,
        team_name: team_name,
        webhook_url: webhook_url,
        type: integration_type
      })

      cond do
        integration_type == "reply" ->
          send_private_channel_instructions(:reply, webhook_url)

        integration_type == "support" && Slack.Helpers.is_private_slack_channel?(channel_id) ->
          send_private_channel_instructions(:support, webhook_url)

        integration_type == "support" ->
          send_support_channel_instructions(webhook_url)

        true ->
          nil
      end

      Slack.Helpers.send_internal_notification(
        "#{email} successfully linked Slack `#{inspect(integration_type)}` integration to channel `#{
          channel
        }`"
      )

      json(conn, %{data: %{ok: true}})
    else
      {:error, :duplicate_channel_id} ->
        conn
        |> put_status(400)
        |> json(%{
          error: %{
            status: 400,
            message: """
            This Slack channel has already been connected with another integration.
            Please select another channel, or disconnect the other integration and try again.
            """
          }
        })

      error ->
        Logger.error(inspect(error))

        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "OAuth access denied: #{inspect(error)}"}})
    end
  end

  @spec authorization(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def authorization(conn, payload) do
    filters = %{type: Map.get(payload, "type", "reply")}

    conn
    |> Pow.Plug.current_user()
    |> Map.get(:account_id)
    |> SlackAuthorizations.get_authorization_by_account(filters)
    |> case do
      nil ->
        json(conn, %{data: nil})

      auth ->
        conn
        |> put_view(SlackAuthorizationView)
        |> render("show.json", slack_authorization: auth)
    end
  end

  @spec update_settings(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def update_settings(conn, %{"id" => id, "settings" => settings}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %SlackAuthorization{} = auth <-
           SlackAuthorizations.get_slack_authorization!(id),
         {:ok, %SlackAuthorization{} = authorization} <-
           SlackAuthorizations.update_slack_authorization(auth, %{settings: settings}) do
      conn
      |> put_view(SlackAuthorizationView)
      |> render("show.json", slack_authorization: authorization)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, %{"id" => id}) do
    with %{account_id: _account_id} <- conn.assigns.current_user,
         %SlackAuthorization{} = auth <-
           SlackAuthorizations.get_slack_authorization!(id),
         {:ok, %SlackAuthorization{}} <- SlackAuthorizations.delete_slack_authorization(auth) do
      send_resp(conn, :no_content, "")
    end
  end

  @spec webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def webhook(conn, payload) do
    Logger.debug("Payload from Slack webhook: #{inspect(payload)}")

    case payload do
      %{"event" => _event, "is_ext_shared_channel" => true} ->
        handle_webhook_payload(payload)
        send_resp(conn, 200, "")

      %{"event" => event} ->
        handle_webhook_event(event)
        send_resp(conn, 200, "")

      %{"challenge" => challenge} ->
        send_resp(conn, 200, challenge)

      _ ->
        send_resp(conn, 200, "")
    end
  end

  @spec actions(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def actions(conn, %{"payload" => json}) do
    Logger.debug("Payload from Slack action: #{inspect(json)}")

    with {:ok, %{"actions" => actions}} <- Jason.decode(json) do
      Enum.each(actions, &handle_action/1)
    end

    send_resp(conn, 200, "")
  end

  def actions(conn, params) do
    Logger.debug("Payload from unhandled Slack action: #{inspect(params)}")

    send_resp(conn, 200, "")
  end

  @spec channels(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def channels(conn, payload) do
    # TODO: figure out the best way to handle errors here... should we just return
    # an empty list of channels if the call fails, or indicate that an error occurred?
    with %{account_id: account_id} <- conn.assigns.current_user,
         filters <- %{type: Map.get(payload, "type", "support")},
         %{access_token: access_token} <-
           SlackAuthorizations.get_authorization_by_account(account_id, filters),
         {:ok, result} <- Slack.Client.list_channels(access_token),
         %{body: %{"ok" => true, "channels" => channels}} <- result do
      json(conn, %{data: channels})
    end
  end

  @spec handle_action(map()) :: any()
  def handle_action(%{
        "action_id" => "close_conversation",
        "type" => "button",
        "action_ts" => _action_ts,
        "value" => conversation_id
      }) do
    conversation_id
    |> Conversations.get_conversation!()
    |> Conversations.update_conversation(%{"status" => "closed"})
    |> case do
      {:ok, conversation} ->
        conversation
        |> Conversations.Notification.notify(:slack)
        |> Conversations.Notification.notify(:webhooks, event: "conversation:updated")

      _ ->
        nil
    end
  end

  def handle_action(%{
        "action_id" => "open_conversation",
        "type" => "button",
        "action_ts" => _action_ts,
        "value" => conversation_id
      }) do
    conversation_id
    |> Conversations.get_conversation!()
    |> Conversations.update_conversation(%{"status" => "open"})
    |> case do
      {:ok, conversation} ->
        conversation
        |> Conversations.Notification.notify(:slack)
        |> Conversations.Notification.notify(:webhooks, event: "conversation:updated")

      _ ->
        nil
    end
  end

  @spec handle_webhook_payload(map()) :: any()
  defp handle_webhook_payload(payload) do
    # TODO: figure out a better way to handle this in tests
    case Application.get_env(:chat_api, :environment) do
      :test -> Slack.Event.handle_payload(payload)
      _ -> Task.start(fn -> Slack.Event.handle_payload(payload) end)
    end
  end

  @spec handle_webhook_event(map()) :: any()
  defp handle_webhook_event(event) do
    # TODO: figure out a better way to handle this in tests
    case Application.get_env(:chat_api, :environment) do
      :test -> Slack.Event.handle_event(event)
      _ -> Task.start(fn -> Slack.Event.handle_event(event) end)
    end
  end

  # TODO: maybe it would make more sense to put these in the Slack.Notification module
  @spec send_private_channel_instructions(:reply | :support, binary()) :: any()
  defp send_private_channel_instructions(:reply, webhook_url) do
    message = """
    Hi there! :wave: looks like you've connected Papercups to this channel.

    In order to complete your setup, you'll need to manually add the *Papercups* app this channel.

    You can do this by typing `/app` in the message box below, clicking on "*Add apps to this channel*", and selecting the *Papercups* app.

    (If that doesn't work, try following these instructions: https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)

    Thanks for trying us out! :rocket:
    """

    Logger.info(message)
    # Putting in an async Task for now, since we don't care if this succeeds
    # or fails (and we also don't want it to block anything)
    Task.start(fn -> Slack.Notification.log(message, webhook_url) end)
  end

  defp send_private_channel_instructions(:support, webhook_url) do
    message = """
    Hi there! :wave: looks like you've connected Papercups to a private channel.

    In order to complete your setup, you'll need to manually add the *Papercups* app to this channel, as well as any other channels in which you'd like it to be active.

    You can do this by typing `/app` in the message box below, click on "*Add apps to this channel*", and selecting the *Papercups* app.

    (If that doesn't work, try following these instructions: https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)

    Thanks for trying us out! :rocket:
    """

    Logger.info(message)
    # Putting in an async Task for now, since we don't care if this succeeds
    # or fails (and we also don't want it to block anything)
    Task.start(fn -> Slack.Notification.log(message, webhook_url) end)
  end

  @spec send_support_channel_instructions(binary()) :: any()
  defp send_support_channel_instructions(webhook_url) do
    message = """
    Hi there! :wave:

    If you'd like to sync messages with Papercups in other channels, you'll need to manually add the *Papercups* app to them.

    You can do this by going to the channels you want to sync, typing `/app` in the message box, clicking on "*Add apps to this channel*", and selecting the *Papercups* app.

    (If that doesn't work, try following these instructions: https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace)

    Thanks for trying us out! :rocket:
    """

    Logger.info(message)
    # Putting in an async Task for now, since we don't care if this succeeds
    # or fails (and we also don't want it to block anything)
    Task.start(fn -> Slack.Notification.log(message, webhook_url) end)
  end
end
