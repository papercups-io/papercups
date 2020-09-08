defmodule ChatApiWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel("room:*", ChatApiWeb.RoomChannel)
  channel("conversation:*", ChatApiWeb.ConversationChannel)
  channel("notification:*", ChatApiWeb.NotificationChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case get_credentials(socket, token, otp_app: :chat_api) do
      nil -> :error
      user -> {:ok, assign(socket, :current_user, user)}
    end
  end

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     ChatApiWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil

  defp get_credentials(socket, signed_token, config) do
    conn = %Plug.Conn{secret_key_base: socket.endpoint.config(:secret_key_base)}
    store_config = [backend: Pow.Store.Backend.EtsCache]
    salt = Atom.to_string(ChatApiWeb.APIAuthPlug)

    with {:ok, token} <- Pow.Plug.verify_token(conn, salt, signed_token, config),
         {user, _metadata} <- Pow.Store.CredentialsCache.get(store_config, token) do
      user
    else
      _any -> nil
    end
  end
end
