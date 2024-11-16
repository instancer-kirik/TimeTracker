# lib/time_tracker_web/components/user_day_label_component.ex
defmodule TimeTrackerWeb.UserLabelLive.UserLabelComponent do
  use TimeTrackerWeb, :live_component
  import Phoenix.LiveView.Helpers  # Add this line
  import Phoenix.Component
  alias TimeTracker.Calendar.DayData
  @impl true
  def mount(socket) do
    {:ok, assign(socket, color_picker_open: nil, new_color: "#000000")}  # Initialize new_color
  end

  @impl true
  def update(assigns, socket) do
    user_color_palettes = TimeTracker.Accounts.list_user_color_palettes(assigns.current_user.id)

    # Get the first palette or create a default one if none exists
    current_palette = List.first(user_color_palettes) || %{id: nil}

    applied_label_ids = Map.keys(assigns.day_data.label_colors || %{})  # Use label_colors for applied labels
    applied_labels = Enum.filter(assigns.user_labels, &(to_string(&1.id) in applied_label_ids))
    available_labels = Enum.reject(assigns.user_labels, &(to_string(&1.id) in applied_label_ids))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user_color_palettes, user_color_palettes)
     |> assign(:current_palette_id, current_palette.id)
     |> assign(:available_labels, available_labels)
     |> assign(:applied_labels, applied_labels)  # Updated key
     |> assign(:show_label_selection, false)
     |> assign(:color_picker_open, nil)}
  end

  @impl true
  def handle_event("update_label_color", %{"color" => color, "value" => label_id}, socket) do
    # Update the label_colors without resetting the form
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, label_id, color)
    updated_day_data = %{socket.assigns.day_data | label_colors: updated_label_colors}

    # Debugging: Log the updated day_data
    IO.inspect(updated_day_data, label: "Updated Day Data After Color Update")

    send(self(), {:update_day_data, updated_day_data})

    {:noreply,
     socket
     |> assign(:day_data, updated_day_data)
     |> assign(:color_picker_open, nil)}  # Close the color picker
  end


  @impl true
  def handle_event("select_color", %{"color" => color, "lid" => lid}, socket) do
    # Update the label color in the day_data
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, lid, color)

    # Create the updated day_data, preserving other fields
    updated_day_data = %{socket.assigns.day_data |
      label_colors: updated_label_colors,
      date: socket.assigns.day_data.date,
      mood: socket.assigns.day_data.mood,
      notes: socket.assigns.day_data.notes
    }

    # Notify the parent to update, including all day_data fields
    send(self(), {:update_day_data, updated_day_data})

    {:noreply, assign(socket, day_data: updated_day_data)}
  end
  @impl true
  def handle_event("add_label_to_day", %{"id" => label_id}, socket) do
    # Update the label_colors without resetting the form
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, label_id, "#default_color")  # Replace with actual color logic

    updated_day_data = %{socket.assigns.day_data | label_colors: updated_label_colors}

    send(self(), {:update_day_data, updated_day_data})

    {:noreply, assign(socket, :day_data, updated_day_data)}  # Update the socket with the new day_data
  end

  @impl true
  def handle_event("remove_label_from_day", %{"id" => id}, socket) do
    updated_label_colors = Map.delete(socket.assigns.day_data.label_colors || %{}, id)
    updated_day_data = Map.put(socket.assigns.day_data, :label_colors, updated_label_colors)

    send(self(), {:update_day_data, updated_day_data})

    {:noreply,
     socket
     |> assign(:day_data, updated_day_data)
     |> update_labels()}
  end

  @impl true
  def handle_event("toggle_label_selection", _, socket) do
    # Toggle the visibility of available labels
    show_label_selection = not socket.assigns.show_label_selection
    {:noreply, assign(socket, show_label_selection: show_label_selection)}
  end

  defp toggle_label_selection(applied_labels, label_id) do
    if label_id in applied_labels do
      List.delete(applied_labels, label_id)
    else
      [label_id | applied_labels]
    end
  end

  @impl true
  def handle_event("open_color_picker", %{"id" => id}, socket) do
    {:noreply, assign(socket, :color_picker_open, String.to_integer(id))}
  end

  @impl true
  def handle_event("close_color_picker", _, socket) do
    {:noreply, assign(socket, :color_picker_open, nil)}
  end

  @impl true
  def handle_event("toggle_eyedropper", _, socket) do
    color_picker_id = "color-picker-#{socket.assigns.color_picker_open}"
    send_update(TimeTrackerWeb.ColorPickerComponent, id: color_picker_id, eyedropper_active: true)
    {:noreply, push_event(socket, "toggle_eyedropper", %{id: color_picker_id})}
  end

  defp update_labels(socket) do
    applied_label_ids = Map.keys(socket.assigns.day_data.label_colors || %{})
    applied_labels = Enum.filter(socket.assigns.user_labels, &(to_string(&1.id) in applied_label_ids))
    available_labels = Enum.reject(socket.assigns.user_labels, &(to_string(&1.id) in applied_label_ids))

    socket
    |> assign(:applied_labels, applied_labels)
    |> assign(:available_labels, available_labels)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3>Labels</h3>
      <div class="applied-labels">
        <%= for label <- @applied_labels do %>
          <div class="applied-label flex items-center p-2 border rounded-md mb-2">
            <div class="color-box w-6 h-6 rounded-full mr-2 cursor-pointer"
                 style={"background-color: #{@day_data.label_colors[Integer.to_string(label.id)] || label.color};"}
                 phx-click="open_color_picker"
                 phx-value-id={label.id}
                 phx-target={@myself}></div>
            <span class="flex-grow"><%= label.name %></span>
            <button type="button" class="text-sm bg-red-500 text-white px-2 py-1 rounded ml-2"
                    phx-click="remove_label_from_day"
                    phx-value-id={label.id}
                    phx-target={@myself}>Remove</button>
          </div>
          <%= if @color_picker_open == label.id do %>

          <div>
              <h3>Color Palettes</h3>
              <%= for palette <- @user_color_palettes do %>
                <div>
                  <h4><%= palette.name %></h4>
                  <div>
                    <%= for color <- palette.colors do %>
                      <div style={"background-color: #{color};"}></div>
                    <% end %>
                  </div>
                </div>
              <% end %>

            <.live_component
              module={TimeTrackerWeb.ColorPickerComponent}
              id={"color-picker-#{label.id}"}
              hex_color={@day_data.label_colors[Integer.to_string(label.id)] || label.color}
              palette_id={@current_palette_id}
              label_id={label.id}
              selected_color={@selected_color}
              selected_palette_id = {@selected_palette_id}
              new_color={@new_color}
              parent={@myself}
            />
            </div>
          <% end %>
        <% end %>
      </div>

      <button phx-click="toggle_label_selection" phx-target={@myself}>
        <%= if @show_label_selection, do: "Hide", else: "Show" %> Available Labels
      </button>

      <%= if @show_label_selection do %>
        <div class="available-labels mt-4">
          <%= for label <- @available_labels do %>
            <button class="bg-blue-500 text-white px-2 py-1 rounded mr-2 mb-2"
                    phx-click="add_label_to_day"
                    phx-value-id={label.id}
                    phx-target={@myself}>
              <%= label.name %>
            </button>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:update_label_color, color, label_id}, socket) do
    # Logic to update the label color in the socket or database
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, label_id, color)

    # Update the day_data in the socket
    updated_day_data = %{socket.assigns.day_data | label_colors: updated_label_colors}

    # Assign the updated day_data back to the socket
    {:noreply, assign(socket, day_data: updated_day_data)}
  end
  @impl true
  def handle_info({:close_color_picker, _id}, socket) do
    {:noreply, assign(socket, color_picker_open: nil)}  # Close the color picker
  end
end
