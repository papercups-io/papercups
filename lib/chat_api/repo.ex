defmodule ChatApi.Repo do
  @cursor_pagination_defaults [
    maximum_limit: 50
  ]

  use Ecto.Repo,
    otp_app: :chat_api,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 50

  @spec paginate_with_cursor(any, keyword, any) :: Paginator.Page.t()
  def paginate_with_cursor(queryable, opts \\ [], repo_opts \\ []) do
    opts = Keyword.merge(@cursor_pagination_defaults, opts)
    Paginator.paginate(queryable, opts, __MODULE__, repo_opts)
  end
end
