defmodule TimeTrackerWeb.ReminderFormComponent do
  use TimeTrackerWeb, :live_component

  alias TimeTracker.Calendar

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4"><%= @title %></h2>

      <.form
        for={@form}
        id="reminder-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <div>
            <.input field={@form[:title]} type="text" label="Title" required />
          </div>

          <div>
            <.input field={@form[:description]} type="textarea" label="Description" />
          </div>

          <div>
            <.input
              field={@form[:calendar_system_id]}
              type="select"
              label="Calendar System"
              options={Enum.map(@calendar_systems, &{&1.name, &1.id})}
              required
            />
          </div>

          <div>
            <.input
              field={@form[:time_of_day]}
              type="time"
              label="Time"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Days of Week</label>
            <div class="flex flex-wrap gap-2">
              <%= for {day, index} <- Enum.with_index(@calendar_systems |> List.first() |> Map.get(:day_names), 1) do %>
                <label class="inline-flex items-center">
                  <input
                    type="checkbox"
                    name={"reminder[days_of_week][]"}
                    value={index}
                    checked={index in (@form[:days_of_week].value || [])}
                    class="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
                  />
                  <span class="ml-2 text-sm text-gray-700"><%= day %></span>
                </label>
              <% end %>
            </div>
          </div>

          <div>
            <label class="inline-flex items-center">
              <.input field={@form[:active]} type="checkbox" />
              <span class="ml-2">Active</span>
            </label>
          </div>

          <div class="flex justify-end space-x-3">
            <.button type="button" phx-click="cancel" phx-target={@myself}>
              Cancel
            </.button>
            <.button type="submit" phx-disable-with="Saving...">
              Save
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{reminder: reminder} = assigns, socket) do
    changeset = Calendar.change_daily_reminder(reminder)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"reminder" => reminder_params}, socket) do
    changeset =
      socket.assigns.reminder
      |> Calendar.change_daily_reminder(reminder_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"reminder" => reminder_params}, socket) do
    save_reminder(socket, socket.assigns.action, reminder_params)
  end

  def handle_event("cancel", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  defp save_reminder(socket, :edit, reminder_params) do
    case Calendar.update_daily_reminder(socket.assigns.reminder, reminder_params) do
      {:ok, _reminder} ->
        {:noreply,
         socket
         |> put_flash(:info, "Reminder updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_reminder(socket, :new, reminder_params) do
    reminder_params = Map.put(reminder_params, "user_id", socket.assigns.current_user.id)

    case Calendar.create_daily_reminder(reminder_params) do
      {:ok, _reminder} ->
        {:noreply,
         socket
         |> put_flash(:info, "Reminder created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end 