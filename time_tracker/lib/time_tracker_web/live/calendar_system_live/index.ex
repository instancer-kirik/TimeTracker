defmodule TimeTrackerWeb.CalendarSystemLive.Index do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar
  alias TimeTracker.Calendar.CalendarSystem

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :calendar_systems, list_calendar_systems())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Calendar System")
    |> assign(:calendar_system, Calendar.get_calendar_system!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Calendar System")
    |> assign(:calendar_system, %CalendarSystem{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Calendar Systems")
    |> assign(:calendar_system, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    calendar_system = Calendar.get_calendar_system!(id)
    {:ok, _} = Calendar.delete_calendar_system(calendar_system)

    {:noreply, assign(socket, :calendar_systems, list_calendar_systems())}
  end

  defp list_calendar_systems do
    Calendar.list_calendar_systems()
  end
end
