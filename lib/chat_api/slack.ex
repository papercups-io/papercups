defmodule ChatApi.Slack do
  @moduledoc """
  A module to handle sending Slack notifications.
  """

  # TODO: play around with using structs to format Slack API responses and webhook events

  defmodule Message do
    @enforce_keys [:text]

    defstruct [
      :blocks,
      :bot_id,
      :client_msg_id,
      :subtype,
      :team,
      :thread_ts,
      :ts,
      :user,
      text: "",
      type: "message"
    ]

    def from_json(json) do
      params = Map.new(json, fn {key, value} -> {String.to_atom(key), value} end)

      struct(Message, params)
    end
  end

  defmodule MessageEvent do
    defstruct [
      :blocks,
      :bot_id,
      :client_msg_id,
      :channel,
      :channel_type,
      :event_ts,
      :subtype,
      :team,
      :thread_ts,
      :ts,
      :user,
      text: "",
      type: "message"
    ]

    def from_json(json) do
      params = Map.new(json, fn {key, value} -> {String.to_atom(key), value} end)

      struct(MessageEvent, params)
    end
  end
end
