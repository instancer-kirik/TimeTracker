# lib/time_tracker_web/components/user_day_label_component.ex
defmodule TimeTrackerWeb.UserLabelLive.UserLabelComponent do
  use TimeTrackerWeb, :live_component
  import Phoenix.LiveView.Helpers  # Add this line
  import Phoenix.Component
  @impl true
  def mount(socket) do
    {:ok, assign(socket, color_picker_open: nil, new_color: "#000000")}  # Initialize new_color
  end

  @impl true
  def update(assigns, socket) do
    user_color_palettes = TimeTracker.Accounts.list_user_color_palettes(assigns.current_user.id)

    # Get the first palette or create a default one if none exists
    current_palette = List.first(user_color_palettes) || %{id: nil}

    selected_label_ids = Map.keys(assigns.day_data.label_colors || %{})
    selected_labels = Enum.filter(assigns.user_labels, &(to_string(&1.id) in selected_label_ids))
    available_labels = Enum.reject(assigns.user_labels, &(to_string(&1.id) in selected_label_ids))

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user_color_palettes, user_color_palettes)
     |> assign(:current_palette_id, current_palette.id)
     |> assign(:available_labels, available_labels)
     |> assign(:selected_labels, selected_labels)
     |> assign(:show_label_selection, false)
     |> assign(:color_picker_open, nil)}
  end

  @impl true
  def handle_event("update_label_color", %{"color" => color}, socket) do
    id = to_string(socket.assigns.color_picker_open)
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, id, color)
    updated_day_data = Map.put(socket.assigns.day_data, :label_colors, updated_label_colors)

    send(self(), {:update_day_data, updated_day_data})

    {:noreply,
     socket
     |> assign(:day_data, updated_day_data)
     |> assign(:color_picker_open, nil)}
  end

  @impl true
  def handle_event("add_label_to_day", %{"id" => id}, socket) do
    label = Enum.find(socket.assigns.user_labels, &(to_string(&1.id) == id))
    updated_label_colors = Map.put(socket.assigns.day_data.label_colors || %{}, id, label.color)
    updated_day_data = Map.put(socket.assigns.day_data, :label_colors, updated_label_colors)

    send(self(), {:update_day_data, updated_day_data})

    {:noreply,
     socket
     |> assign(:day_data, updated_day_data)
     |> update_labels()}
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
    {:noreply, assign(socket, :show_label_selection, !socket.assigns.show_label_selection)}
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
    selected_label_ids = Map.keys(socket.assigns.day_data.label_colors || %{})
    selected_labels = Enum.filter(socket.assigns.user_labels, &(to_string(&1.id) in selected_label_ids))
    available_labels = Enum.reject(socket.assigns.user_labels, &(to_string(&1.id) in selected_label_ids))

    socket
    |> assign(:selected_labels, selected_labels)
    |> assign(:available_labels, available_labels)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3>Labels</h3>
      <div class="selected-labels">
        <%= for label <- @selected_labels do %>
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
              selected_color={@selected_color}
              selected_palette_id = {@selected_palette_id}
              new_color={@new_color}  # Pass new_color
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
  def handle_info({:close_color_picker, _id}, socket) do
    {:noreply, assign(socket, :color_picker_open, nil)}
  end
end
