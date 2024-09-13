defmodule TimeTrackerWeb.DayDataLive.Show do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:day_data, Calendar.get_day_data!(id))}
  end

  defp page_title(:show), do: "Show Day data"
  defp page_title(:edit), do: "Edit Day data"
end
