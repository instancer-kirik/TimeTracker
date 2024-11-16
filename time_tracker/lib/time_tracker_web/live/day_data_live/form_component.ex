defmodule TimeTrackerWeb.DayDataLive.FormComponent do
  use TimeTrackerWeb, :live_component

  alias TimeTracker.Calendar

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2><%= @title %></h2>

      <.form
        for={@form}
        id="day_data-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:mood]} type="text" label="Mood" />
        <.input field={@form[:notes]} type="textarea" label="Notes" />

        <.live_component
          module={TimeTrackerWeb.UserLabelLive.UserLabelComponent}
          id="user-label-component"
          day_data={@day_data}
          current_user={@current_user}
          user_labels={@user_labels}
          applied_labels={@applied_labels}
          selected_color={@selected_color}
          selected_palette_id={@selected_palette_id}
          parent={@myself}
        />

        <div class="mt-6">
          <.button type="submit" phx-disable-with="Saving..." >Save</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{day_data: day_data} = assigns, socket) do
    changeset = Calendar.change_day_data(day_data)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"day_data" => day_data_params}, socket) do
    changeset =
      socket.assigns.day_data
      |> Calendar.change_day_data(day_data_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"day_data" => day_data_params}, socket) do
    save_day_data(socket, socket.assigns.action, day_data_params)
  end

  @impl true
  def handle_info({:update_day_data, updated_day_data}, socket) do
    # Merge the updated day_data with the current form data
    current_form_data = socket.assigns.form.data

    merged_day_data = %{
      current_form_data |
      label_colors: updated_day_data.label_colors,
      date: current_form_data.date || updated_day_data.date,
      mood: current_form_data.mood || updated_day_data.mood,
      notes: current_form_data.notes || updated_day_data.notes
    }

    changeset = Calendar.change_day_data(merged_day_data)

    {:noreply,
     socket
     |> assign(:day_data, merged_day_data)
     |> assign(:changeset, changeset)
     |> assign_form(changeset)}
  end

  defp save_day_data(socket, :edit, day_data_params) do
    IO.inspect(day_data_params, label: "Params in save_day_data")

    case Calendar.update_day_data(socket.assigns.day_data, day_data_params) do
      {:ok, day_data} ->
        notify_parent({:saved, day_data})

        {:noreply,
         socket
         |> put_flash(:info, "Day data updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_day_data(socket, :new, day_data_params) do
    case Calendar.create_day_data(socket.assigns.current_user, day_data_params) do
      {:ok, day_data} ->
        notify_parent({:saved, day_data})

        {:noreply,
         socket
         |> put_flash(:info, "Day data created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
