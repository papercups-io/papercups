defmodule ChatApi.Emails.Email do
  import Swoosh.Email
  import Ecto.Changeset

  @from_address System.get_env("FROM_ADDRESS")
  @backend_url System.get_env("BACKEND_URL") || ""

  defstruct to_address: nil, message: nil

  # TODO: Move conversation id out the mailer should only care about the message
  def send(to_address, message, conversation_id) do
    # Using try catch here because if someone is self hosting and doesn't need the email service it would error out
    # TODO: Find a better solution besides try catch probably in config.exs setup an empty mailer that doesn't do anything
    try do
      link =
        "<a href=\"https://#{@backend_url}/conversations/#{conversation_id}\">View in dashboard</a>"

      msg = "<b>#{message}</b>"
      html = "A new message has arrived:<br />" <> msg <> "<br /><br />" <> link
      text = "A new message has arrived: #{message}"

      new()
      |> to(to_address)
      |> from({"Papercups", @from_address})
      |> subject("A customer has sent you a message!")
      |> html_body(html)
      |> text_body(text)
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
