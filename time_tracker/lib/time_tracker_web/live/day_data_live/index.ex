defmodule TimeTrackerWeb.DayDataLive.Index do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar
  alias TimeTracker.Calendar.DayData

  @impl true
  def mount(_params, session, socket) do
    user = TimeTracker.Accounts.get_user_by_session_token(session["user_token"])
    user_labels = Calendar.list_user_labels(user.id)
    user_color_palettes = TimeTracker.Accounts.list_user_color_palettes(user.id)

    {:ok,
     socket
     |> assign(:current_user, user)
     |> assign(:day_data, %DayData{user_id: user.id, label_colors: %{}})
     |> assign(:user_labels, user_labels)
     |> assign(:user_color_palettes, user_color_palettes)
     |> assign(:selected_palette_id, nil)  # Corrected key name
     |> assign(:selected_color, nil)  # Initialize selected_color
     |> stream(:day_datas, list_day_datas(user))}
  end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Day Data")
    |> assign(:day_data, Calendar.get_day_data!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Day Data")
    |> assign(:day_data, %DayData{date: Date.utc_today(), labels: [], label_colors: %{}})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Day Data")
    |> assign(:day_data, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    day_data = Calendar.get_day_data!(id)
    {:ok, _} = Calendar.delete_day_data(day_data)

    {:noreply, stream_delete(socket, :day_datas, day_data)}
  end

  @impl true
  def handle_info({TimeTrackerWeb.DayDataLive.FormComponent, {:saved, day_data}}, socket) do
    {:noreply, stream_insert(socket, :day_datas, day_data)}
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

  defp list_day_datas(user) do
    Calendar.list_user_day_datas(user.id)
  end

end
