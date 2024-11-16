defmodule TimeTrackerWeb.DayDataLive.Show do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar
  alias TimeTracker.Accounts

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])

    user_labels = Calendar.list_user_labels(user.id)
    user_color_palettes = Accounts.list_user_color_palettes(user.id)

    {:ok,
     socket
     |> assign(:current_user, user)
     |> assign(:user_labels, user_labels)
     |> assign(:user_color_palettes, user_color_palettes)
     |> assign(:selected_palette_id, 1)
     |> assign(:selected_color, nil)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    day_data = Calendar.get_day_data!(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:day_data, day_data)}
  end

  @impl true
  def handle_info({TimeTrackerWeb.DayDataLive.FormComponent, {:saved, day_data}}, socket) do
    # Ensure that you are not trying to access streams if they are not defined
    {:noreply, assign(socket, :day_data, day_data)}
  end

  @impl true
  def handle_info({:update_day_data, updated_day_data}, socket) do
    send_update(TimeTrackerWeb.DayDataLive.FormComponent, id: socket.assigns.day_data.id || :new, day_data: updated_day_data)
    {:noreply, assign(socket, :day_data, updated_day_data)}
  end

  @impl true
  def handle_info({:close_color_picker, picker_id}, socket) do
    # Logic to handle closing the color picker
    {:noreply, assign(socket, color_picker_open: nil)}  # Example: reset the open color picker
  end
  defp page_title(:show), do: "Show Day data"
  defp page_title(:edit), do: "Edit Day data"
end
