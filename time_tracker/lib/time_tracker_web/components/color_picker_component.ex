defmodule TimeTrackerWeb.ColorPickerComponent do


  use TimeTrackerWeb, :live_component
  import Phoenix.HTML.Form
  alias TimeTracker.Calendar.DayData
  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      hex_color: "#000000",
      new_color: "#000000",
      palettes: %{
        1 => [],  # Palette ID 1
        2 => []   # Palette ID 2
      },
      selected_palette_id: 1  # Set a default selected palette ID
    )}
  end

  @impl true
  def render(assigns) do
    palettes = assigns.palettes || %{}  # Default to an empty map if nil

    ~H"""
    <div class="color-picker" id={"color-picker-#{@id}"} phx-hook="ColorPicker">
      <h4>Select a Color</h4>
      <input type="color" value={@hex_color} phx-change="update_hex" phx-target={@myself} name="hex" />

      <%= for color <- @palettes[@selected_palette_id] || [] do %>
        <div style={"background-color: #{color}; cursor: pointer;"}
             phx-click="select_color"
             phx-value-color={color}
             phx-value-lid={@label_id}
             phx-target={@parent}>
        </div>
      <% end %>

      <button type="button"
              phx-click="add_color_to_palette"
              phx-value-color={@new_color}
              phx-target={@myself}>
        Add to Palette
      </button>

      <button type="button"
              phx-click="select_color"
              phx-value-color={@new_color}
              phx-value-lid={@label_id}
              phx-target={@parent}>
        Use for Label <%= @label_id %>
      </button>

      <div class="tabs">
        <%= for {id, colors} <- @palettes do %>
          <button phx-click="select_palette" phx-value-id={id} phx-target={@myself} class={if id == @selected_palette_id, do: "active", else: ""}>
            Palette <%= id %>
          </button>
        <% end %>
      </div>

      <div>
        <h5>Current Colors in Palette <%= @selected_palette_id || "N/A" %>:</h5>
        <ul>
          <%= for color <- @palettes[@selected_palette_id] || [] do %>
            <li>
              <div phx-click="select_color" phx-value-color={color} phx-target={@parent}>
                <div style={"background-color: #{color}; width: 20px; height: 20px; display: inline-block; cursor: pointer;"}></div>
                <%= color %>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
      <button phx-click="close_picker" phx-target={@myself} class="bg-red-500 text-white px-2 py-1 rounded ml-2">
        Close
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("update_hex", %{"hex" => hex}, socket) do
    # Update the selected color in the socket
    {:noreply, assign(socket, new_color: hex)}  # Ensure new_color is updated
  end

  @impl true
  def handle_event("toggle_eyedropper", _, socket) do
    eyedropper_active = !socket.assigns.eyedropper_active
    {:noreply, assign(socket, eyedropper_active: eyedropper_active)}
  end

  @impl true
  def handle_event("add_color_to_palette", %{"color" => color}, socket) do
    # Logic to add the color to the selected palette
    palette_id = socket.assigns.selected_palette_id

    updated_palettes = Map.update!(socket.assigns.palettes, palette_id, fn colors ->
      colors ++ [color]
    end)

    {:noreply, assign(socket, palettes: updated_palettes)}
  end



  @impl true
  def handle_event("close_picker", _, socket) do
    send(self(), {:close_color_picker, socket.assigns.id})  # Notify parent to close the picker
    {:noreply, assign(socket, :color_picker_open, nil)}  # Optionally reset the state in the component
  end

  @impl true
  def handle_event("eyedropper_color_picked", %{"color" => color}, socket) do
    {red, green, blue} = hex_to_rgb(color)
    {:noreply, assign(socket, hex_color: color, red: red, green: green, blue: blue, last_selected_color: color)}
  end

  defp hex_to_rgb("#" <> hex_color) do
    {String.to_integer(String.slice(hex_color, 0, 2), 16),
     String.to_integer(String.slice(hex_color, 2, 2), 16),
     String.to_integer(String.slice(hex_color, 4, 2), 16)}
  end

  defp rgb_to_hex(red, green, blue) do
    "##{Integer.to_string(red, 16) |> String.pad_leading(2, "0")}#{Integer.to_string(green, 16) |> String.pad_leading(2, "0")}#{Integer.to_string(blue, 16) |> String.pad_leading(2, "0")}"
  end

  @impl true
  def handle_event("select_palette", %{"id" => id}, socket) do
    selected_palette_id = String.to_integer(id)
    #IO.inspect(selected_palette_id, label: "PICKER-Selected Palette ID")

    # Update the selected_palette_id without closing the picker
    {:noreply, assign(socket, selected_palette_id: selected_palette_id)}
  end

   # Select color for label and notify parent (main update function)
   @impl true
  def handle_event("select_color", %{"color" => color, "value" => value}, socket) do
    # Send the selected color to the parent component
    send(self(), {:update_label_color, color, value})  # Include the value (label ID)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:close_color_picker, _id}, socket) do
    {:noreply, assign(socket, color_picker_open: nil)}  # Close the color picker
  end
end
