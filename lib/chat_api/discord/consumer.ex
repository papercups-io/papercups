defmodule ChatApi.Discord.Consumer do
  @moduledoc """
  Uses the Nostrum library to listen to listen to events from Discord
  """
  use Nostrum.Consumer

  # TODO: use `Nostrum.Api` in `ChatApi.Discord.Client`?
  # alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    IO.inspect(msg, label: "Message created!")

    :noop
  end

  def handle_event({type, payload, _ws_state}) do
    IO.inspect(payload, label: type)

    :noop
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(event) do
    IO.inspect(event, label: "Unhandled event!")

    :noop
  end
end
