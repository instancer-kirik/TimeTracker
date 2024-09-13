defmodule TimeTracker.CalendarTest do
  use TimeTracker.DataCase

  alias TimeTracker.Calendar

  describe "day_datas" do
    alias TimeTracker.Calendar.DayData

    import TimeTracker.CalendarFixtures

    @invalid_attrs %{date: nil, mood: nil, notes: nil}

    test "list_day_datas/0 returns all day_datas" do
      day_data = day_data_fixture()
      assert Calendar.list_day_datas() == [day_data]
    end

    test "get_day_data!/1 returns the day_data with given id" do
      day_data = day_data_fixture()
      assert Calendar.get_day_data!(day_data.id) == day_data
    end

    test "create_day_data/1 with valid data creates a day_data" do
      valid_attrs = %{date: ~D[2024-09-07], mood: "some mood", notes: "some notes"}

      assert {:ok, %DayData{} = day_data} = Calendar.create_day_data(valid_attrs)
      assert day_data.date == ~D[2024-09-07]
      assert day_data.mood == "some mood"
      assert day_data.notes == "some notes"
    end

    test "create_day_data/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendar.create_day_data(@invalid_attrs)
    end

    test "update_day_data/2 with valid data updates the day_data" do
      day_data = day_data_fixture()
      update_attrs = %{date: ~D[2024-09-08], mood: "some updated mood", notes: "some updated notes"}

      assert {:ok, %DayData{} = day_data} = Calendar.update_day_data(day_data, update_attrs)
      assert day_data.date == ~D[2024-09-08]
      assert day_data.mood == "some updated mood"
      assert day_data.notes == "some updated notes"
    end

    test "update_day_data/2 with invalid data returns error changeset" do
      day_data = day_data_fixture()
      assert {:error, %Ecto.Changeset{}} = Calendar.update_day_data(day_data, @invalid_attrs)
      assert day_data == Calendar.get_day_data!(day_data.id)
    end

    test "delete_day_data/1 deletes the day_data" do
      day_data = day_data_fixture()
      assert {:ok, %DayData{}} = Calendar.delete_day_data(day_data)
      assert_raise Ecto.NoResultsError, fn -> Calendar.get_day_data!(day_data.id) end
    end

    test "change_day_data/1 returns a day_data changeset" do
      day_data = day_data_fixture()
      assert %Ecto.Changeset{} = Calendar.change_day_data(day_data)
    end
  end

  describe "calendar_systems" do
    alias TimeTracker.Calendar.CalendarSystem

    import TimeTracker.CalendarFixtures

    @invalid_attrs %{name: nil, week_length: nil, day_one: nil}

    test "list_calendar_systems/0 returns all calendar_systems" do
      calendar_system = calendar_system_fixture()
      assert Calendar.list_calendar_systems() == [calendar_system]
    end

    test "get_calendar_system!/1 returns the calendar_system with given id" do
      calendar_system = calendar_system_fixture()
      assert Calendar.get_calendar_system!(calendar_system.id) == calendar_system
    end

    test "create_calendar_system/1 with valid data creates a calendar_system" do
      valid_attrs = %{name: "some name", week_length: 42, day_one: ~D[2024-09-07]}

      assert {:ok, %CalendarSystem{} = calendar_system} = Calendar.create_calendar_system(valid_attrs)
      assert calendar_system.name == "some name"
      assert calendar_system.week_length == 42
      assert calendar_system.day_one == ~D[2024-09-07]
    end

    test "create_calendar_system/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Calendar.create_calendar_system(@invalid_attrs)
    end

    test "update_calendar_system/2 with valid data updates the calendar_system" do
      calendar_system = calendar_system_fixture()
      update_attrs = %{name: "some updated name", week_length: 43, day_one: ~D[2024-09-08]}

      assert {:ok, %CalendarSystem{} = calendar_system} = Calendar.update_calendar_system(calendar_system, update_attrs)
      assert calendar_system.name == "some updated name"
      assert calendar_system.week_length == 43
      assert calendar_system.day_one == ~D[2024-09-08]
    end

    test "update_calendar_system/2 with invalid data returns error changeset" do
      calendar_system = calendar_system_fixture()
      assert {:error, %Ecto.Changeset{}} = Calendar.update_calendar_system(calendar_system, @invalid_attrs)
      assert calendar_system == Calendar.get_calendar_system!(calendar_system.id)
    end

    test "delete_calendar_system/1 deletes the calendar_system" do
      calendar_system = calendar_system_fixture()
      assert {:ok, %CalendarSystem{}} = Calendar.delete_calendar_system(calendar_system)
      assert_raise Ecto.NoResultsError, fn -> Calendar.get_calendar_system!(calendar_system.id) end
    end

    test "change_calendar_system/1 returns a calendar_system changeset" do
      calendar_system = calendar_system_fixture()
      assert %Ecto.Changeset{} = Calendar.change_calendar_system(calendar_system)
    end
  end
end
