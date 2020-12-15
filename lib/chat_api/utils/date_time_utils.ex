defmodule ChatApi.Utils.DateTimeUtils do
  require Logger

  @midnight ~T[00:00:00]

  @spec minutes_since_midnight(DateTime.t()) :: float()
  def minutes_since_midnight(datetime) do
    datetime
    |> DateTime.to_time()
    |> Time.diff(@midnight)
    |> Kernel./(60)
  end

  @spec current_minutes_since_midnight(binary() | nil) :: float() | nil
  def current_minutes_since_midnight(time_zone) when is_binary(time_zone) do
    case DateTime.now(time_zone) do
      {:ok, datetime} ->
        minutes_since_midnight(datetime)

      {:error, reason} ->
        Logger.error("Invalid time zone #{inspect(time_zone)} - #{inspect(reason)}")

        nil
    end
  end

  def current_minutes_since_midnight(_), do: nil

  @spec day_of_week(DateTime.t()) :: Calendar.day()
  def day_of_week(datetime) do
    datetime |> DateTime.to_date() |> Date.day_of_week()
  end
end
