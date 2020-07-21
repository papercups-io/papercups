defmodule ChatApi.Emails.Email do
  import Swoosh.Email
  import Ecto.Changeset

  @from_address System.get_env("FROM_ADDRESS")

  defstruct to_address: nil, message: nil

  # TODO: Move conversation id out the mailer should only care about the message
  def send(to_address, message, conversation_id) do
    # Using try catch here because if someone is self hosting and doesn't need the email service it would error out
    # TODO: Find a better solution besides try catch probably in config.exs setup an empty mailer that doesn't do anything
    try do
      body =
        "A new message has arrived: " <>
          message <> "\nhttps://www.papercups.io/conversations/" <> conversation_id

      new()
      |> to(to_address)
      |> from({"hello", @from_address})
      |> subject("A customer has sent you a message!")
      |> text_body(body)
      |> ChatApi.Mailer.deliver()
    rescue
      e ->
        IO.puts(
          "Email config environment variable may not have been setup properly: #{e.message}"
        )
    end
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(email, attrs) do
    email
    |> cast(attrs, [:to_address, :message])
    |> validate_required([:to_address, :message])
  end
end
