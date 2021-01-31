defmodule ChatApiWeb.SlackController do
  use ChatApiWeb, :controller

  require Logger

  alias ChatApi.{Slack, SlackAuthorizations}
  alias ChatApi.SlackAuthorizations.SlackAuthorization

  action_fallback(ChatApiWeb.FallbackController)

  @spec oauth(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def oauth(conn, %{"code" => code} = params) do
    Logger.info("Code from Slack OAuth: #{inspect(code)}")

    # TODO: improve error handling?
    with %{account_id: account_id, email: email} <- conn.assigns.current_user,
         {:ok, response} <- Slack.Client.get_access_token(code),
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
         %{
           "channel" => channel,
           "channel_id" => channel_id,
           "configuration_url" => configuration_url,
           "url" => webhook_url
         } <- incoming_webhook do
      integration_type = Map.get(params, "type", "reply")

      params = %{
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
      }

      # TODO: after creating, check if connected channel is private;
      # If yes, use webhook_url to send notification that Papercups app needs
      # to be added manually, along with instructions for how to do so
      SlackAuthorizations.create_or_update(account_id, params)

      cond do
        integration_type == "reply" && Slack.Helpers.is_private_slack_channel?(channel_id) ->
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
      error ->
        Logger.error(error)

        raise "OAuth access denied: #{inspect(error)}"
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
        json(conn, %{
          data: %{
            id: auth.id,
            created_at: auth.inserted_at,
            channel: auth.channel,
            configuration_url: auth.configuration_url,
            team_name: auth.team_name
          }
        })
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
        Slack.Event.handle_payload(payload)
        send_resp(conn, 200, "")

      %{"event" => event} ->
        Slack.Event.handle_event(event)
        send_resp(conn, 200, "")

      %{"challenge" => challenge} ->
        send_resp(conn, 200, challenge)

      _ ->
        send_resp(conn, 200, "")
    end
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

  # TODO: maybe it would make more sense to put these in the Slack.Notification module
  @spec send_private_channel_instructions(:reply | :support, binary()) :: any()
  defp send_private_channel_instructions(:reply, webhook_url) do
    message = """
    Hi there! :wave: looks like you've connected Papercups to a private channel.

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
