defmodule TimeTracker.CalendarFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TimeTracker.Calendar` context.
  """

  @doc """
  Generate a day_data.
  """
  def day_data_fixture(attrs \\ %{}) do
    {:ok, day_data} =
      attrs
      |> Enum.into(%{
        date: ~D[2024-09-07],
        mood: "some mood",
        notes: "some notes"
      })
      |> TimeTracker.Calendar.create_day_data()

    day_data
  end

  @doc """
  Generate a calendar_system.
  """
  def calendar_system_fixture(attrs \\ %{}) do
    {:ok, calendar_system} =
      attrs
      |> Enum.into(%{
        day_one: ~D[2024-09-07],
        name: "some name",
        week_length: 42
      })
      |> TimeTracker.Calendar.create_calendar_system()

    calendar_system
  end
end
