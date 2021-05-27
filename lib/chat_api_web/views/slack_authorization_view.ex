defmodule ChatApiWeb.SlackAuthorizationView do
  use ChatApiWeb, :view
  alias ChatApiWeb.SlackAuthorizationView
  alias ChatApi.SlackAuthorizations

  def render("show.json", %{slack_authorization: slack_authorization}) do
    %{
      data:
        render_one(
          slack_authorization,
          SlackAuthorizationView,
          "slack_authorization.json"
        )
    }
  end

  def render("slack_authorization.json", %{
        slack_authorization: slack_authorization
      }) do
    %{
      id: slack_authorization.id,
      object: "slack_authorization",
      account_id: slack_authorization.account_id,
      channel: slack_authorization.channel,
      configuration_url: slack_authorization.configuration_url,
      team_name: slack_authorization.team_name,
      created_at: slack_authorization.inserted_at,
      updated_at: slack_authorization.updated_at,
      settings:
        render("settings.json", %{
          settings: SlackAuthorizations.get_authorization_settings(slack_authorization)
        })
    }
  end

  def render("settings.json", %{settings: settings}) do
    %{
      sync_all_incoming_threads: settings.sync_all_incoming_threads,
      sync_by_emoji_tagging: settings.sync_by_emoji_tagging,
      sync_trigger_emoji: settings.sync_trigger_emoji,
      forward_synced_messages_to_reply_channel: settings.forward_synced_messages_to_reply_channel
    }
  end
end
