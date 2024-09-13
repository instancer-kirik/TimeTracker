defmodule TimeTrackerWeb.CalendarSystemLive.FormComponent do
  use TimeTrackerWeb, :live_component

  alias TimeTracker.Calendar

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage calendar_system records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="calendar_system-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:week_length]} type="number" label="Week length" />
        <.input field={@form[:day_one]} type="date" label="Day one" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Calendar system</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{calendar_system: calendar_system} = assigns, socket) do
    changeset = Calendar.change_calendar_system(calendar_system)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"calendar_system" => calendar_system_params}, socket) do
    changeset =
      socket.assigns.calendar_system
      |> Calendar.change_calendar_system(calendar_system_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"calendar_system" => calendar_system_params}, socket) do
    save_calendar_system(socket, socket.assigns.action, calendar_system_params)
  end

  defp save_calendar_system(socket, :edit, calendar_system_params) do
    case Calendar.update_calendar_system(socket.assigns.calendar_system, calendar_system_params) do
      {:ok, calendar_system} ->
        notify_parent({:saved, calendar_system})

        {:noreply,
         socket
         |> put_flash(:info, "Calendar system updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_calendar_system(socket, :new, calendar_system_params) do
    case Calendar.create_calendar_system(calendar_system_params) do
      {:ok, calendar_system} ->
        notify_parent({:saved, calendar_system})

        {:noreply,
         socket
         |> put_flash(:info, "Calendar system created successfully")
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
