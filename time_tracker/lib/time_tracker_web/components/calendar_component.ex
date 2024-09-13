defmodule TimeTrackerWeb.CalendarLive.CalendarComponent do
  use TimeTrackerWeb, :live_component

  alias TimeTracker.Calendar

  @impl true
  def render(assigns) do
    ~H"""
    <div class="calendar">
      <h2><%= @year %> - <%= month_name(@month) %></h2>
      <div class="grid grid-cols-7 gap-1">
        <%= for day <- 1..days_in_month(@year, @month) do %>
          <div class="day-cell" phx-click="edit_day" phx-value-date={Date.new!(@year, @month, day)} phx-target={@myself}>
            <span class="date"><%= day %></span>
            <%= if day_data = get_day_data(@day_datas, @year, @month, day) do %>
              <div class="mood"><%= day_data.mood %></div>
              <div class="notes"><%= truncate(day_data.notes, 30) %></div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("edit_day", %{"date" => date}, socket) do
    date = Date.from_iso8601!(date)
    day_data = get_day_data(socket.assigns.day_datas, date.year, date.month, date.day) || %Calendar.DayData{}

    {:noreply,
     socket
     |> assign(:editing_date, date)
     |> assign(:editing_day_data, day_data)
     |> assign(:show_modal, true)}
  end

  defp get_day_data(day_datas, year, month, day) do
    Enum.find(day_datas, fn data -> Date.new!(year, month, day) == data.date end)
  end

  defp days_in_month(year, month), do: Date.days_in_month(Date.new!(year, month, 1))

  defp month_name(month), do: Calendar.month_name(month)

  defp truncate(string, length) do
    if String.length(string) > length do
      String.slice(string, 0, length) <> "..."
    else
      string
    end
  end
end
