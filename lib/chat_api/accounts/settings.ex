defmodule ChatApi.Accounts.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          disable_automated_reply_emails: boolean(),
          conversation_reminders_enabled: boolean(),
          conversation_reminder_hours_interval: integer(),
          max_num_conversation_reminders: integer()
        }

  embedded_schema do
    field(:disable_automated_reply_emails, :boolean)
    field(:conversation_reminders_enabled, :boolean)
    field(:conversation_reminder_hours_interval, :integer)
    field(:max_num_conversation_reminders, :integer)
  end

  @spec changeset(any(), map()) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, [
      :disable_automated_reply_emails,
      :conversation_reminders_enabled,
      :conversation_reminder_hours_interval,
      :max_num_conversation_reminders
    ])
  end
end
