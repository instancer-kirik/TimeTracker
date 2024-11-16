defmodule TimeTrackerWeb.DayDataLive.Index do
  use TimeTrackerWeb, :live_view

  alias TimeTracker.Calendar
  alias TimeTracker.Calendar.DayData

  @impl true
  def mount(_params, session, socket) do
    user = TimeTracker.Accounts.get_user_by_session_token(session["user_token"])
    user_labels = Calendar.list_user_labels(user.id)
    user_color_palettes = TimeTracker.Accounts.list_user_color_palettes(user.id)

    # Ensure day_data is fetched or initialized if it doesn't already exist in the socket
    day_data = socket.assigns[:day_data] || %DayData{label_colors: %{}}

    {:ok,
    socket
    |> assign(:current_user, user)
    |> assign(:day_data, day_data)  # Preserve day_data
    |> assign(:user_labels, user_labels)
    |> assign(:user_color_palettes, user_color_palettes)
    |> assign(:applied_labels, [])  # Ensure this is assigned
    |> assign(:selected_palette_id, 1)
    |> assign(:selected_color, nil)
    |> stream(:day_datas, list_day_datas(user))}
  end


  @impl true
  def handle_params(params, _url, socket) do
    changeset = Calendar.change_day_data(socket.assigns.day_data)

    # Get applied labels from day_data
    applied_labels = Map.keys(socket.assigns.day_data.label_colors || %{})

    # Call apply_action and ensure it returns the correct format
    case apply_action(socket, socket.assigns.live_action, params, changeset, applied_labels) do
      {:noreply, updated_socket} ->
        {:noreply, updated_socket}  # Correct return format
      other ->
        IO.inspect(other, label: "Unexpected Return from apply_action")  # Debugging
        {:noreply, socket}  # Fallback to ensure a valid return
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}, changeset) do
    day_data = Calendar.get_day_data!(id)
    applied_labels = Map.keys(day_data.label_colors || %{})

    socket
    |> assign(:page_title, "Edit Day Data")
    |> assign(:day_data, day_data)
    |> assign(:applied_labels, applied_labels)
    |> then(&{:noreply, &1})  # Ensure this returns the correct format
  end

  defp apply_action(socket, :new, _params, changeset, applied_labels) do
    socket
    |> assign(:page_title, "New Day Data")
    |> assign(:day_data, %TimeTracker.Calendar.DayData{user_id: socket.assigns.current_user.id, label_colors: %{}})  # Initialize with user_id
    |> assign(:form, changeset)  # Pass the changeset as form
    |> assign(:applied_labels, applied_labels)  # Pass applied_labels to the form
    |> then(&{:noreply, &1})  # Ensure this returns the correct format
  end

  defp apply_action(socket, :index, _params) do
    # Handle the index action if necessary
    socket
    |> assign(:page_title, "Listing Day Data")
    |> assign(:day_data, nil)

  end

  defp apply_action(socket, action, _params, _changeset, _applied_labels) do
    IO.inspect(action, label: "Unexpected Action")
    {:noreply, socket}  # Handle unexpected actions
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
    applied_labels = Map.keys(updated_day_data.label_colors || %{})

    send_update(TimeTrackerWeb.DayDataLive.FormComponent,
      id: socket.assigns.day_data.id || :new,
      day_data: updated_day_data,
      applied_labels: applied_labels  # Include applied_labels in the update
    )
    IO.inspect(updated_day_data, label: "updated day data in Index.update")

    {:noreply, assign(socket, :day_data, updated_day_data)}  # Update the socket with the new day_data
  end

  @impl true
  def handle_info({:close_color_picker, picker_id}, socket) do
    # Logic to handle closing the color picker
    {:noreply, assign(socket, color_picker_open: nil)}  # Example: reset the open color picker
  end

  @impl true
  def handle_info({:update_label_color, color, label_id}, socket) do
    # Update the label_colors in the day_data
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, label_id, color)

    # Create the updated day_data
    updated_day_data = %{socket.assigns.day_data | label_colors: updated_label_colors}

    # Send an update to the form component
    send_update(TimeTrackerWeb.DayDataLive.FormComponent,
      id: socket.assigns.day_data.id || :new,
      day_data: updated_day_data,
      applied_labels: Map.keys(updated_label_colors)  # Include applied_labels in the update
    )

    # Log the updated day data for debugging
    IO.inspect(updated_day_data, label: "Updated Day Data in handle_info")

    {:noreply, assign(socket, :day_data, updated_day_data)}  # Update the socket with the new day_data
  end

  defp list_day_datas(user) do
    Calendar.list_user_day_datas(user.id)
  end

end
