defmodule TimeTracker.Calendar do
  @moduledoc """
  The Calendar context.
  """

  import Ecto.Query, warn: false
  alias TimeTracker.Repo
  alias TimeTracker.Accounts.User
  alias TimeTracker.Calendar.DayData
  alias TimeTracker.Calendar.CalendarSystem
  alias TimeTracker.Calendar.Event
  alias TimeTracker.Calendar.UserLabel
  alias TimeTracker.Calendar.DailyReminder

  # DayData functions
  def list_user_day_datas(user_id) do
    DayData
    |> where([d], d.user_id == ^user_id)
    |> preload(:labels)
    |> Repo.all()
  end
  def list_user_events(user) do
    Repo.all(Ecto.assoc(user, :events))
  end

  def list_user_day_datas(user) do
    Repo.all(Ecto.assoc(user, :day_datas))
  end
  @doc """
  Returns the list of day_datas.
  """
  def list_day_datas do
    Repo.all(DayData)
  end

  @doc """
  Gets a single day_data.

  Raises `Ecto.NoResultsError` if the Day data does not exist.
  """
  def get_day_data!(id) do
    DayData
    |> Repo.get!(id)
    |> Repo.preload(:labels)
  end
  def get_events_for_day(user_id, date) do
    from(e in Event,
      where: e.user_id == ^user_id and
             fragment("DATE(?)", e.start_time) <= ^date and
             fragment("DATE(?)", e.end_time) >= ^date
    )
    |> Repo.all()
  end
  def get_labels_by_ids(label_ids) do
    UserLabel
    |> where([l], l.id in ^label_ids)
    |> Repo.all()
  end
  @doc """
  Creates a day_data.
  """
  def create_day_data(user, attrs \\ %{}) do
    %DayData{}
    |> DayData.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def create_day_data(user, attrs, labels) do
    %DayData{}
    |> DayData.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:labels, labels)
    |> Repo.insert()
  end
  def create_day_data(user, attrs, label_ids) do
    labels = get_labels_by_ids(label_ids)

    %DayData{}
    |> DayData.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:labels, labels)
    |> Repo.insert()
  end
  @doc """
  Updates a day_data.
  """
  def update_day_data(%DayData{} = day_data, attrs) do
    day_data
    |> DayData.changeset(attrs)
    |> Repo.update()
  end
  def update_day_data_with_labels(%DayData{} = day_data, attrs, user) do
    day_data
    |> DayData.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:labels, get_labels_by_ids(attrs["label_ids"] || []))
    |> Repo.update()
  end
  @doc """
  Deletes a day_data.
  """
  def delete_day_data(%DayData{} = day_data) do
    Repo.delete(day_data)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking day_data changes.
  """
  def change_day_data(%DayData{} = day_data, attrs \\ %{}) do
    #attrs = Map.put(attrs, :user_id, day_data.user_id)  # Ensure user_id is included
    DayData.changeset(day_data, attrs)
  end
  def create_user_label(user, attrs \\ %{}) do
    Logger.info("Creating user label: #{inspect(attrs)}")

    %UserLabel{}
    |> UserLabel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
    |> case do
      {:ok, label} ->
        Logger.info("User label created: #{inspect(label)}")
        {:ok, label}
      {:error, changeset} ->
        Logger.error("Failed to create user label: #{inspect(changeset)}")
        {:error, changeset}
    end
  end
  def list_user_labels(user_id) do
    UserLabel
    |> where(user_id: ^user_id)
    |> Repo.all()
  end
  # CalendarSystem functions

  @doc """
  Returns the list of calendar_systems.
  """
  def list_calendar_systems do
    Repo.all(CalendarSystem)
  end

  @doc """
  Gets a single calendar_system.

  Raises `Ecto.NoResultsError` if the Calendar system does not exist.
  """
  def get_calendar_system!(id), do: Repo.get!(CalendarSystem, id)

  @doc """
  Creates a calendar_system.
  """
  def create_calendar_system(attrs \\ %{}) do
    %CalendarSystem{}
    |> CalendarSystem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a calendar_system.
  """
  def update_calendar_system(%CalendarSystem{} = calendar_system, attrs) do
    calendar_system
    |> CalendarSystem.changeset(attrs)
    |> Repo.update()
  end
  # Helper function to insert or update
  defp upsert_calendar_system(attrs) do
    case Repo.get_by(CalendarSystem, name: attrs.name) do
      nil -> %CalendarSystem{}
      calendar_system -> calendar_system
    end
    |> CalendarSystem.changeset(attrs)
    |> Repo.insert_or_update!()
  end
  @doc """
  Deletes a calendar_system.
  """
  def delete_calendar_system(%CalendarSystem{} = calendar_system) do
    Repo.delete(calendar_system)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking calendar_system changes.
  """
  def change_calendar_system(%CalendarSystem{} = calendar_system, attrs \\ %{}) do
    CalendarSystem.changeset(calendar_system, attrs)
  end

  # Date conversion functions



  @doc """
  Determines if a given year has a leap month in a custom calendar system.
  """
  def leap_month?(year, calendar_system) do
    rule = calendar_system.leap_month_rule
    case rule["type"] do
      "cyclic" ->
        rem(year, rule["cycle"]) in rule["leap_years"]
      "calculation" ->
        expr = rule["expression"]
        |> String.replace("year", to_string(year))
        |> Code.string_to_quoted!()
        {result, _} = Code.eval_quoted(expr)
        result
      _ ->
        false
    end
  end

  @doc """
  Returns the list of months for a given year, including the leap month if applicable.
  """
  def months_in_year(year, calendar_system) do
    extra_day_months = extra_days_distribution(year, calendar_system)

    base_months = calendar_system.months
    |> Enum.with_index(1)
    |> Enum.map(fn {month, index} ->
      extra_days = if index in extra_day_months, do: 1, else: 0
      Map.update!(month, "length", &(&1 + extra_days))
    end)

    if leap_month?(year, calendar_system) do
      leap_month = calendar_system.leap_month
      {before_leap, [leap_and_after]} = Enum.split(base_months, leap_month["after"])
      before_leap ++ [leap_month, leap_and_after]
    else
      base_months
    end
  end

  @doc """
  Returns the number of days in a given year for a custom calendar system.
  """
  def days_in_year(year, calendar_system) do
    months_in_year(year, calendar_system)
    |> Enum.sum(&(&1["length"]))
  end

  @doc """
  Determines if a given year is a leap year in a custom calendar system.
  """
  def leap_year?(year, calendar_system) do
    rule = calendar_system.leap_year_rule
    case rule["type"] do
      "cyclic" ->
        rem(year, rule["cycle"]) in rule["leap_years"]
      "calculation" ->
        expr = rule["expression"]
        |> String.replace("year", to_string(year))
        |> Code.string_to_quoted!()
        {result, _} = Code.eval_quoted(expr)
        result
      _ ->
        false
    end
  end

  @doc """
  Determines which months get extra days in a leap year.
  """
  def extra_days_distribution(year, calendar_system) do
    calendar_system.extra_days_distribution
    |> Enum.filter(fn rule ->
      case rule["condition"] do
        "always" -> true
        "leap_year" -> leap_year?(year, calendar_system)
        expr ->
          {result, _} = Code.eval_string(expr, [year: year])
          result
      end
    end)
    |> Enum.flat_map(& &1["months"])
  end

  @doc """
  Returns the number of days in a given month, considering leap years, leap months, and extra days distribution.
  """
  def days_in_month(year, month, calendar_system) do
    months_in_year(year, calendar_system)
    |> Enum.at(month - 1)
    |> Map.get("length")
  end

  @doc """
  Converts a custom calendar system date to a Gregorian date, handling leap years and leap months.
  """
  def custom_to_gregorian({year, month, day}, calendar_system) do
    days = Enum.reduce(1..(year - 1), 0, fn y, acc ->
      acc + days_in_year(y, calendar_system)
    end)
    months = months_in_year(year, calendar_system)
    days = days + Enum.sum(Enum.map(Enum.take(months, month - 1), &(&1["length"])))
    days = days + day - 1
    Date.add(calendar_system.day_one, days)
  end

  @doc """
  Converts a Gregorian date to a custom calendar system date, handling leap years and leap months.
  """
  def gregorian_to_custom(date, calendar_system) do
    days_since_epoch = Date.diff(date, calendar_system.day_one)

    {year, day_of_year} = Enum.reduce_while(Stream.iterate(1, &(&1 + 1)), {0, days_since_epoch + 1}, fn year, {_, remaining_days} ->
      year_length = days_in_year(year, calendar_system)
      if remaining_days > year_length do
        {:cont, {year, remaining_days - year_length}}
      else
        {:halt, {year, remaining_days}}
      end
    end)

    months = months_in_year(year, calendar_system)
    {month, day} = Enum.reduce_while(months, {1, day_of_year}, fn month, {month_num, remaining_days} ->
      if remaining_days > month["length"] do
        {:cont, {month_num + 1, remaining_days - month["length"]}}
      else
        {:halt, {month_num, remaining_days}}
      end
    end)

    {year, month, day}
  end

  def calendar_days(year, month, calendar_system) do
    months = months_in_year(year, calendar_system)
    month_data = Enum.at(months, month - 1)
    first_day = custom_to_gregorian({year, month, 1}, calendar_system)
    last_day = custom_to_gregorian({year, month, month_data["length"]}, calendar_system)

    pad_start = day_of_week(first_day, calendar_system) - 1
    pad_end = (calendar_system.week_length - day_of_week(last_day, calendar_system)) |> rem(calendar_system.week_length)

    (Date.add(first_day, -pad_start) ..  Date.add(last_day, pad_end))
    |> Enum.map(fn date ->
      custom_date = gregorian_to_custom(date, calendar_system)
      %{
        date: date,
        day: elem(custom_date, 2),
        current_month: elem(custom_date, 1) == month,
        custom_date: custom_date
      }
    end)
  end

  def month_name(month, calendar_system) do
    months = calendar_system.months ++ [calendar_system.leap_month]
    months
    |> Enum.at(month - 1)
    |> Map.get("name", month_name(month))
  end
  defp month_name(month) do
    Enum.at(~w(January February March April May June July August September October November December), month - 1, "Unknown")
  end
  def day_name(date) do
    Enum.at(~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday), Date.day_of_week(date) - 1)
  end

  def day_name(date, calendar_system) do
    day_of_week = day_of_week(date, calendar_system)
    calendar_system.day_names
    |> Enum.at(day_of_week - 1, day_name(date))
  end

  def date_to_string(date) do
    "#{month_name(date.month)} #{date.day}, #{date.year}"
  end

  def date_to_string(date, calendar_system) do
    "#{month_name(date.month, calendar_system)} #{date.day}, #{date.year}"
  end

  def today(calendar_system) do
    gregorian_to_custom(Date.utc_today(), calendar_system)
  end

  def add_days({year, month, day}, days, calendar_system) do
    date = custom_to_gregorian({year, month, day}, calendar_system)
    new_date = Date.add(date, days)
    gregorian_to_custom(new_date, calendar_system)
  end

  def week_range(date, calendar_system) do
    day_of_week = day_of_week(date, calendar_system)
    start_of_week = add_days(date, -(day_of_week - 1), calendar_system)
    end_of_week = add_days(start_of_week, calendar_system.week_length - 1, calendar_system)
    {start_of_week, end_of_week}
  end

  @doc """
  Calculates the difference in days between two dates in a custom calendar system.
  """
  def date_diff({year1, month1, day1}, {year2, month2, day2}, calendar_system) do
    date1 = custom_to_gregorian({year1, month1, day1}, calendar_system)
    date2 = custom_to_gregorian({year2, month2, day2}, calendar_system)
    Date.diff(date2, date1)
  end

  @doc """
  Adds a specified number of years to a date in a custom calendar system.
  """
  def add_years({year, month, day}, years_to_add, calendar_system) do
    new_year = year + years_to_add
    month_data = Enum.at(calendar_system.months, month - 1)
    new_day = min(day, month_data["length"])
    {new_year, month, new_day}
  end

  @doc """
  Adds a specified number of months to a date in a custom calendar system.
  """
  def add_months({year, month, day}, months_to_add, calendar_system) do
    total_months = (year * length(calendar_system.months)) + month - 1 + months_to_add
    new_year = div(total_months, length(calendar_system.months))
    new_month = rem(total_months, length(calendar_system.months)) + 1
    month_data = Enum.at(calendar_system.months, new_month - 1)
    new_day = min(day, month_data["length"])
    {new_year, new_month, new_day}
  end

  @doc """
  Returns the day of the year for a given date in a custom calendar system.
  """
  def day_of_year({year, month, day}, calendar_system) do
    months = months_in_year(year, calendar_system)
    preceding_months = Enum.take(months, month - 1)
    preceding_days = Enum.sum(Enum.map(preceding_months, & &1["length"]))
    preceding_days + day
  end
  @doc """
  Calculates the day of the week for a given date in a custom calendar system.
  """
  def day_of_week(date, calendar_system) do
    days_since_epoch = Date.diff(date, calendar_system.day_one)
    rem(days_since_epoch, calendar_system.week_length) + 1
  end
  @doc """
  Calculates the week number for a given date in a custom calendar system.
  """
  def week_of_year({year, month, day}, calendar_system) do
    days = day_of_year({year, month, day}, calendar_system)
    first_day = day_of_week(custom_to_gregorian({year, 1, 1}, calendar_system), calendar_system)
    div(days + first_day - 2, calendar_system.week_length) + 1
  end

  @doc """
  Returns the next occurrence of a specific day of the week.
  """
  def next_day_of_week({year, month, day}, target_day, calendar_system) do
    current_day = day_of_week(custom_to_gregorian({year, month, day}, calendar_system), calendar_system)
    days_to_add = rem(target_day - current_day + calendar_system.week_length, calendar_system.week_length)
    add_days({year, month, day}, days_to_add, calendar_system)
  end

  @doc """
  Calculates the number of days between two dates in a custom calendar system.
  """
  def days_between({year1, month1, day1}, {year2, month2, day2}, calendar_system) do
    date1 = custom_to_gregorian({year1, month1, day1}, calendar_system)
    date2 = custom_to_gregorian({year2, month2, day2}, calendar_system)
    Date.diff(date2, date1)
  end

  @doc """
  Determines if a given date is a weekend in a custom calendar system.
  Assumes the last day(s) of the week are weekend days.
  """
  def weekend?({year, month, day}, calendar_system) do
    day_num = day_of_week(custom_to_gregorian({year, month, day}, calendar_system), calendar_system)
    day_num > calendar_system.week_length - 2
  end

  def create_event(attrs, user) do
    attrs = convert_times_to_utc(attrs, user.time_zone)
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  defp convert_times_to_utc(attrs, time_zone) do
    start_time = parse_and_convert_to_utc(attrs["start_date"], attrs["start_time"], time_zone)
    end_time = parse_and_convert_to_utc(attrs["end_date"], attrs["end_time"], time_zone)

    attrs
    |> Map.put("start_time", start_time)
    |> Map.put("end_time", end_time)
  end

  defp parse_and_convert_to_utc(date_string, time_string, time_zone) do
    {:ok, naive_datetime} = NaiveDateTime.new(date_string, time_string)
    {:ok, local_datetime} = DateTime.from_naive(naive_datetime, time_zone)
    DateTime.shift_zone!(local_datetime, "Etc/UTC")
  end

  def custom_date_to_utc_datetime(custom_date, time, calendar_system, time_zone) do
    gregorian_date = TimeTracker.Calendar.custom_to_gregorian(custom_date, calendar_system)
    {:ok, naive_datetime} = NaiveDateTime.new(gregorian_date, time)
    {:ok, local_datetime} = DateTime.from_naive(naive_datetime, time_zone)
    DateTime.shift_zone!(local_datetime, "Etc/UTC")
  end

  @doc """
  Returns a list of user labels for a given user_id.
  """
  def list_user_labels(user_id) do
    UserLabel
    |> where(user_id: ^user_id)
    |> Repo.all()
  end

  def get_user_color_palette(user_id) do
    Accounts.get_user_color_palette(user_id)
    # Return a list of color strings, e.g., ["#FF0000", "#00FF00", "#0000FF"]
  end

  def delete_user_label(label_id) do
    label = Repo.get(UserLabel, label_id)
    Repo.delete(label)
  end
 T
  defp get_labels_from_ids(label_ids) do
    UserLabel
    |> where([l], l.id in ^label_ids)
    |> Repo.all()
  end

  def update_day_data_with_labels(%DayData{} = day_data, attrs, user) do
    day_data
    |> DayData.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:labels, get_labels_from_ids(attrs["label_ids"] || []))
    |> Repo.update()
  end

  @doc """
  Creates a daily reminder.
  """
  def create_daily_reminder(attrs \\ %{}) do
    %DailyReminder{}
    |> DailyReminder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns daily reminders for a specific user and day of week.
  """
  def get_daily_reminders(user_id, day_of_week, calendar_system_id) do
    DailyReminder
    |> where([r], r.user_id == ^user_id)
    |> where([r], ^day_of_week in r.days_of_week)
    |> where([r], r.calendar_system_id == ^calendar_system_id)
    |> where([r], r.active == true)
    |> order_by([r], r.time_of_day)
    |> Repo.all()
  end

  @doc """
  Updates a daily reminder.
  """
  def update_daily_reminder(%DailyReminder{} = reminder, attrs) do
    reminder
    |> DailyReminder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a daily reminder.
  """
  def delete_daily_reminder(%DailyReminder{} = reminder) do
    Repo.delete(reminder)
  end

  def get_user_reminders(user_id) do
    DailyReminder
    |> where(user_id: ^user_id)
    |> order_by([r], [r.time_of_day, r.title])
    |> Repo.all()
  end

  def get_daily_reminder!(id) do
    Repo.get!(DailyReminder, id)
  end

  def change_daily_reminder(%DailyReminder{} = reminder, attrs \\ %{}) do
    DailyReminder.changeset(reminder, attrs)
  end
end
