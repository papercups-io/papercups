defmodule ChatApiWeb.PersonalApiKeyView do
  use ChatApiWeb, :view
  alias ChatApiWeb.PersonalApiKeyView

  def render("index.json", %{personal_api_keys: personal_api_keys}) do
    %{data: render_many(personal_api_keys, PersonalApiKeyView, "personal_api_key.json")}
  end

  def render("show.json", %{personal_api_key: personal_api_key}) do
    %{data: render_one(personal_api_key, PersonalApiKeyView, "personal_api_key.json")}
  end

  def render("personal_api_key.json", %{personal_api_key: personal_api_key}) do
    %{
      id: personal_api_key.id,
      object: "personal_api_key",
      label: personal_api_key.label,
      value: personal_api_key.value,
      last_used_at: personal_api_key.last_used_at,
      account_id: personal_api_key.account_id,
      user_id: personal_api_key.user_id
    }
  end
end
