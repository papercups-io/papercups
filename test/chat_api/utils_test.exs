defmodule ChatApi.UtilsTest do
  use ChatApi.DataCase, async: true
  import ExUnit.CaptureLog
  alias ChatApi.Utils

  describe "date_time_utils" do
    test "minutes_since_midnight/1" do
      assert 60.0 = Utils.DateTimeUtils.minutes_since_midnight(~U[2020-12-10 01:00:00Z])
      assert 600.0 = Utils.DateTimeUtils.minutes_since_midnight(~U[2020-12-10 10:00:00Z])
      assert 105.0 = Utils.DateTimeUtils.minutes_since_midnight(~U[2020-12-10 01:45:00Z])
      assert 780.0 = Utils.DateTimeUtils.minutes_since_midnight(~U[2020-12-10 13:00:00Z])
    end

    test "current_minutes_since_midnight/1 returns a float for valid time zones" do
      utc = Utils.DateTimeUtils.current_minutes_since_midnight("Etc/UTC")
      nyc = Utils.DateTimeUtils.current_minutes_since_midnight("America/New_York")

      assert is_float(utc)
      assert is_float(nyc)
    end

    test "current_minutes_since_midnight/1 returns nil when time zone is nil" do
      refute Utils.DateTimeUtils.current_minutes_since_midnight(nil)
    end

    test "current_minutes_since_midnight/1 returns nil for invalid time zones" do
      assert capture_log(fn ->
               refute Utils.DateTimeUtils.current_minutes_since_midnight("Invalid/Timezone")
             end) =~ "Invalid time zone"
    end

    test "day_of_week/1" do
      # Monday
      assert 1 = Utils.DateTimeUtils.day_of_week(~U[2020-12-07 10:00:00Z])
      # Tuesday
      assert 2 = Utils.DateTimeUtils.day_of_week(~U[2020-12-08 10:00:00Z])
      # Wednesday
      assert 3 = Utils.DateTimeUtils.day_of_week(~U[2020-12-09 10:00:00Z])
      # Thursday
      assert 4 = Utils.DateTimeUtils.day_of_week(~U[2020-12-10 10:00:00Z])
      # Friday
      assert 5 = Utils.DateTimeUtils.day_of_week(~U[2020-12-11 10:00:00Z])
      # Saturday
      assert 6 = Utils.DateTimeUtils.day_of_week(~U[2020-12-12 10:00:00Z])
      # Sunday
      assert 7 = Utils.DateTimeUtils.day_of_week(~U[2020-12-13 10:00:00Z])
    end
  end
end
