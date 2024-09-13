defmodule TimeTrackerWeb.ColorPickerComponent do


  use TimeTrackerWeb, :live_component
  import Phoenix.HTML.Form

  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      hex_color: "#000000",
      red: 0,
      green: 0,
      blue: 0,
      eyedropper_active: false,
      last_selected_color: nil
    )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="color-picker" id={"color-picker-#{@id}"} phx-hook="ColorPicker">
      <h4>Select a Color</h4>
      <input type="color" value={@hex_color} phx-change="update_hex" phx-target={@myself} name="hex" />
      <button type="button"
              phx-click="add_color_to_palette"
              phx-value-palette-id={@palette_id}
              phx-value-value={@new_color}
              phx-target={@myself}>
        Add Color
      </button>
      <button phx-click="close_picker" phx-target={@myself} class="bg-red-500 text-white px-2 py-1 rounded ml-2">
        Close
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("update_hex", %{"hex" => hex}, socket) do
    # Update the selected color in the socket
    {:noreply, assign(socket, selected_color: hex)}
  end

  @impl true
  def handle_event("toggle_eyedropper", _, socket) do
    eyedropper_active = !socket.assigns.eyedropper_active
    {:noreply, assign(socket, eyedropper_active: eyedropper_active)}
  end

  @impl true
  def handle_event("add_color_to_palette", %{"palette-id" => palette_id, "value" => color}, socket) do
    if String.trim(color) == "" do
      {:noreply, put_flash(socket, :error, "Color cannot be empty")}
    else
      # Proceed to add the color to the palette
      case TimeTracker.Accounts.add_color_to_palette(palette_id, color) do
        {:ok, _palette} ->
          # Update the socket assigns to reflect the new palette state
          updated_palettes = TimeTracker.Accounts.list_user_color_palettes(socket.assigns.current_user.id)
          {:noreply, assign(socket, user_color_palettes: updated_palettes)}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to add color: #{reason}")}
      end
    end
  end

  @impl true
  def handle_event("close_picker", _, socket) do
    send(self(), {:close_color_picker, socket.assigns.id})
    {:noreply, socket}
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

end
