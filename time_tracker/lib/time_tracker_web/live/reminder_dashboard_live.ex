defmodule TimeTrackerWeb.ReminderDashboardLive do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar
  alias TimeTracker.Calendar.DailyReminder

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      user = socket.assigns.current_user
      reminders = Calendar.get_user_reminders(user.id)
      calendar_systems = Calendar.list_calendar_systems()

      {:ok,
       socket
       |> assign(:reminders, reminders)
       |> assign(:calendar_systems, calendar_systems)
       |> assign(:show_form, false)
       |> assign(:editing_reminder, nil)}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Daily Reminders</h1>
        <button
          class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          phx-click="new_reminder"
        >
          New Reminder
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for reminder <- @reminders do %>
          <div class="bg-white p-4 rounded-lg shadow">
            <div class="flex justify-between items-start mb-2">
              <h3 class="text-lg font-semibold"><%= reminder.title %></h3>
              <div class="flex space-x-2">
                <button
                  class="text-gray-600 hover:text-blue-500"
                  phx-click="edit_reminder"
                  phx-value-id={reminder.id}
                >
                  <.icon name="hero-pencil" class="h-5 w-5" />
                </button>
                <button
                  class="text-gray-600 hover:text-red-500"
                  phx-click="delete_reminder"
                  phx-value-id={reminder.id}
                  data-confirm="Are you sure you want to delete this reminder?"
                >
                  <.icon name="hero-trash" class="h-5 w-5" />
                </button>
              </div>
            </div>

            <p class="text-gray-600 mb-2"><%= reminder.description %></p>
            <div class="flex flex-wrap gap-2 mb-2">
              <%= for day <- reminder.days_of_week do %>
                <span class="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">
                  <%= day_name(day, get_calendar_system(reminder.calendar_system_id, @calendar_systems)) %>
                </span>
              <% end %>
            </div>
            <div class="flex justify-between items-center text-sm text-gray-500">
              <span><%= format_time(reminder.time_of_day) %></span>
              <div class="flex items-center gap-2">
                <span class={[
                  "px-2 py-1 rounded text-xs",
                  reminder.active && "bg-green-100 text-green-800",
                  !reminder.active && "bg-gray-100 text-gray-800"
                ]}>
                  <%= if reminder.active, do: "Active", else: "Inactive" %>
                </span>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if @show_form do %>
        <.modal id="reminder-modal" show={true} on_cancel={JS.patch(~p"/reminders")}>
          <.live_component
            module={TimeTrackerWeb.ReminderFormComponent}
            id={@editing_reminder && @editing_reminder.id || :new}
            title={@page_title}
            action={@live_action}
            reminder={@editing_reminder || %DailyReminder{}}
            calendar_systems={@calendar_systems}
            current_user={@current_user}
            patch={~p"/reminders"}
          />
        </.modal>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("new_reminder", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_reminder, nil)
     |> assign(:page_title, "New Reminder")
     |> assign(:live_action, :new)}
  end

  def handle_event("edit_reminder", %{"id" => id}, socket) do
    reminder = Calendar.get_daily_reminder!(id)
    {:noreply,
     socket
     |> assign(:show_form, true)
     |> assign(:editing_reminder, reminder)
     |> assign(:page_title, "Edit Reminder")
     |> assign(:live_action, :edit)}
  end

  def handle_event("delete_reminder", %{"id" => id}, socket) do
    reminder = Calendar.get_daily_reminder!(id)
    {:ok, _} = Calendar.delete_daily_reminder(reminder)

    {:noreply,
     socket
     |> assign(:reminders, Calendar.get_user_reminders(socket.assigns.current_user.id))
     |> put_flash(:info, "Reminder deleted successfully")}
  end

  defp day_name(day_number, calendar_system) do
    calendar_system.day_names
    |> Enum.at(day_number - 1, "Unknown")
  end

  defp format_time(time) do
    Calendar.strftime(time, "%I:%M %p")
  end

  defp get_calendar_system(id, calendar_systems) do
    Enum.find(calendar_systems, &(&1.id == id))
  end
end 