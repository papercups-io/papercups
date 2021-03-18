defmodule ChatApi.CannedResponses do
  defdelegate authorize(action, user, params), to: ChatApi.CannedResponses.Policy

  @moduledoc """
  The CannedResponses context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.CannedResponses.CannedResponse

  @spec list_canned_responses() :: [CannedResponse.t()]
  def list_canned_responses do
    Repo.all(CannedResponse)
  end

  @spec list_canned_responses(binary()) :: [CannedResponse.t()]
  def list_canned_responses(account_id) do
    CannedResponse |> where(account_id: ^account_id) |> Repo.all()
  end

  @spec get_canned_response!(binary()) :: CannedResponse.t()
  def get_canned_response!(id), do: Repo.get!(CannedResponse, id)

  @spec create_canned_response(map()) :: {:ok, CannedResponse.t()} | {:error, Ecto.Changeset.t()}
  def create_canned_response(attrs \\ %{}) do
    %CannedResponse{}
    |> CannedResponse.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_canned_response(CannedResponse.t(), map()) ::
          {:ok, CannedResponse.t()} | {:error, Ecto.Changeset.t()}
  def update_canned_response(%CannedResponse{} = canned_response, attrs) do
    canned_response
    |> CannedResponse.changeset(attrs)
    |> Repo.update()
  end

  @spec delete_canned_response(CannedResponse.t()) ::
          {:ok, CannedResponse.t()} | {:error, Ecto.Changeset.t()}
  def delete_canned_response(%CannedResponse{} = canned_response) do
    Repo.delete(canned_response)
  end

  @spec change_canned_response(CannedResponse.t(), map()) :: Ecto.Changeset.t()
  def change_canned_response(%CannedResponse{} = canned_response, attrs \\ %{}) do
    CannedResponse.changeset(canned_response, attrs)
  end
end

defmodule ChatApi.CannedResponses.Policy do
  @behaviour Bodyguard.Policy

  # Require account_id check for getting, updating, deleting
  def authorize(
        action,
        %{account_id: account_id} = _user,
        %{account_id: account_id} = _canned_response
      )
      when action in [:get_canned_response!, :update_canned_response, :delete_canned_response],
      do: :ok

  # Don't require authorization check when listing or creating
  def authorize(action, _, _)
      when action in [:list_canned_responses, :create_canned_response],
      do: :ok

  # Catch-all: deny everything else
  def authorize(_, _, _), do: {:error, :not_found}
end
