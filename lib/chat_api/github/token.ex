defmodule ChatApi.Github.Token do
  @moduledoc """
  A module for handling Github JWTs
  """

  use Joken.Config

  @impl true
  def token_config do
    default_claims(
      iss: System.get_env("PAPERCUPS_GITHUB_APP_ID"),
      default_exp: 10 * 60
    )
  end
end
