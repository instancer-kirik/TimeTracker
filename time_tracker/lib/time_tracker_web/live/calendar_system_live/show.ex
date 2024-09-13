defmodule TimeTrackerWeb.CalendarSystemLive.Show do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar
  alias TimeTracker.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    today = Date.utc_today()

    {:ok,
     socket
     |> assign(:current_user, user)
     |> assign(:current_date, today)
     |> assign(:view, :month)  # Default view
     |> assign(:day_data_filled, false)
     |> assign(:show_modal, false)
     |> assign(:editing_day_data, %Calendar.DayData{})}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    calendar_system = Calendar.get_calendar_system!(id)
    day_datas = Calendar.list_user_day_datas(socket.assigns.current_user.id, socket.assigns.current_date.year, socket.assigns.current_date.month)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:calendar_system, calendar_system)
     |> assign(:day_datas, day_datas)
     |> assign(:example_year, generate_example_year(calendar_system))}
  end

  @impl true
  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view, String.to_atom(view))}
  end

  @impl true
  def handle_event("change_date", %{"date" => date}, socket) do
    new_date = Date.from_iso8601!(date)
    {:noreply, update_date(socket, new_date)}
  end

  @impl true
  def handle_event("navigate", %{"direction" => direction}, socket) do
    new_date = case socket.assigns.view do
      :year -> navigate_year(socket.assigns.current_date, direction)
      :month -> navigate_month(socket.assigns.current_date, direction)
      :week -> navigate_week(socket.assigns.current_date, direction)
      :day -> navigate_day(socket.assigns.current_date, direction)
    end
    {:noreply, update_date(socket, new_date)}
  end

  @impl true
  def handle_event("edit_day", %{"date" => date}, socket) do
    date = Date.from_iso8601!(date)
    day_data = get_day_data(socket.assigns.day_datas, date) || %Calendar.DayData{date: date}

    {:noreply,
     socket
     |> assign(:editing_day_data, day_data)
     |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("save_day_data", %{"day_data" => day_data_params}, socket) do
    day_data_params = Map.put(day_data_params, "user_id", socket.assigns.current_user.id)

    case Calendar.create_or_update_day_data(day_data_params) do
      {:ok, _day_data} ->
        day_datas = Calendar.list_user_day_datas(socket.assigns.current_user.id, socket.assigns.year, socket.assigns.month)
        {:noreply,
         socket
         |> assign(:day_datas, day_datas)
         |> assign(:show_modal, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("fill_day_data", _, socket) do
    filled_year = fill_with_sample_day_data(socket.assigns.example_year)
    {:noreply, socket |> assign(:example_year, filled_year) |> assign(:day_data_filled, true)}
  end

  defp update_date(socket, new_date) do
    day_datas = Calendar.list_user_day_datas(socket.assigns.current_user.id, new_date.year, new_date.month)
    socket
    |> assign(:current_date, new_date)
    |> assign(:day_datas, day_datas)
  end

  defp navigate_year(date, direction) do
    case direction do
      "prev" -> %{date | year: date.year - 1}
      "next" -> %{date | year: date.year + 1}
    end
  end

  defp navigate_month(date, direction) do
    case direction do
      "prev" -> Date.add(date, -Calendar.days_in_month(date.year, date.month))
      "next" -> Date.add(date, Calendar.days_in_month(date.year, date.month))
    end
  end

  defp navigate_week(date, direction) do
    case direction do
      "prev" -> Date.add(date, -7)
      "next" -> Date.add(date, 7)
    end
  end

  defp navigate_day(date, direction) do
    case direction do
      "prev" -> Date.add(date, -1)
      "next" -> Date.add(date, 1)
    end
  end

  defp get_day_data(day_datas, date) do
    Enum.find(day_datas, fn data -> data.date == date end)
  end

  defp get_calendar_data(calendar_system, date, view) do
    case view do
      :year ->
        Enum.map(1..12, fn m ->
          calendar_days(date.year, m, calendar_system)
        end)
      :month ->
        calendar_days(date.year, date.month, calendar_system)
      :week ->
        start_of_week = Date.beginning_of_week(date, :monday)
        Enum.map(0..6, fn d -> Date.add(start_of_week, d) end)
        |> Enum.map(fn d -> %{date: d, day: d.day, current_month: d.month == date.month} end)
      :day ->
        [%{date: date, day: date.day, current_month: true}]
    end
  end

  defp calendar_days(year, month, calendar_system) do
    first_day = Date.new!(year, month, 1)
    last_day = Date.new!(year, month, Calendar.days_in_month(year, month, calendar_system))

    pad_start = Calendar.day_of_week(first_day, calendar_system) - 1
    pad_end = (calendar_system.week_length - Calendar.day_of_week(last_day, calendar_system)) |> rem(calendar_system.week_length)

    (Date.add(first_day, -pad_start) ..  Date.add(last_day, pad_end))
    |> Enum.map(fn date ->
      %{
        date: date,
        day: date.day,
        current_month: date.month == month,
        custom_date: Calendar.gregorian_to_custom(date, calendar_system)
      }
    end)
  end

  defp page_title(:show), do: "Show Calendar System"
  defp page_title(:edit), do: "Edit Calendar System"

  defp generate_example_year(calendar_system) do
    total_days = Enum.sum(Enum.map(calendar_system.months, & &1["length"]))

    days = for day <- 1..total_days do
      custom_date = Calendar.get_custom_date(day, calendar_system)
      {Date.add(calendar_system.day_one, day - 1), custom_date}
    end

    Enum.chunk_by(days, fn {_, {month, _, _}} -> month end)
  end

  defp get_custom_date(day, calendar_system) do
    {month, month_day} = get_month_and_day(day, calendar_system.months)
    week = div(month_day - 1, calendar_system.week_length)
    day_of_week = rem(month_day - 1, calendar_system.week_length)
    {month, {week, day_of_week}}
  end

  defp get_month_and_day(day, months) do
    Enum.reduce_while(months, {day, 1}, fn month, {remaining_days, month_num} ->
      if remaining_days <= month["length"] do
        {:halt, {month_num, remaining_days}}
      else
        {:cont, {remaining_days - month["length"], month_num + 1}}
      end
    end)
  end

  defp fill_with_sample_day_data(year) do
    Enum.map(year, fn month ->
      Enum.map(month, fn {date, custom_date} ->
        day_data = %{mood: random_mood(), notes: "Sample note for #{date}"}
        {date, custom_date, day_data}
      end)
    end)
  end

  defp random_mood do
    Enum.random(["Happy", "Sad", "Neutral", "Excited", "Tired"])
  end

  defp truncate(string, length) do
    if String.length(string) > length do
      String.slice(string, 0, length) <> "..."
    else
      string
    end
  end

  defp mood_color(nil), do: ""
  defp mood_color(%{mood: "Happy"}), do: "bg-green-200"
  defp mood_color(%{mood: "Sad"}), do: "bg-blue-200"
  defp mood_color(%{mood: "Neutral"}), do: "bg-yellow-200"
  defp mood_color(%{mood: "Excited"}), do: "bg-purple-200"
  defp mood_color(%{mood: "Tired"}), do: "bg-gray-200"
  defp mood_color(_), do: ""
end
