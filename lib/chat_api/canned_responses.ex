defmodule ChatApi.CannedResponses do
  @moduledoc """
  The CannedResponses context.
  """

  import Ecto.Query, warn: false
  alias ChatApi.Repo

  alias ChatApi.CannedResponses.CannedResponse


  def list_canned_responses do
    Repo.all(CannedResponse)
  end

  def list_canned_responses(account_id) do
    CannedResponse |> where(account_id: ^account_id) |> Repo.all()
  end

  def get_canned_response!(id), do: Repo.get!(CannedResponse, id)

  def create_canned_response(attrs \\ %{}) do
    %CannedResponse{}
    |> CannedResponse.changeset(attrs)
    |> Repo.insert()
  end

  def update_canned_response(%CannedResponse{} = canned_response, attrs) do
    canned_response
    |> CannedResponse.changeset(attrs)
    |> Repo.update()
  end

  def delete_canned_response(%CannedResponse{} = canned_response) do
    Repo.delete(canned_response)
  end

  def change_canned_response(%CannedResponse{} = canned_response, attrs \\ %{}) do
    CannedResponse.changeset(canned_response, attrs)
  end
end
