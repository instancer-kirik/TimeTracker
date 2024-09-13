defmodule TimeTracker.Calendar.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :title, :string
    field :description, :string  # DB column is TEXT
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :custom_start_date, :map
    field :custom_end_date, :map
    belongs_to :user, TimeTracker.Accounts.User
    belongs_to :calendar_system, TimeTracker.Calendar.CalendarSystem

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :description, :start_time, :end_time, :custom_start_date, :custom_end_date, :user_id, :calendar_system_id])
    |> validate_required([:title, :start_time, :end_time, :user_id, :calendar_system_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:calendar_system_id)
    |> validate_custom_dates()
  end

  defp validate_custom_dates(changeset) do
    case {get_field(changeset, :custom_start_date), get_field(changeset, :custom_end_date)} do
      {nil, nil} -> changeset
      {start, end_date} when is_map(start) and is_map(end_date) ->
        validate_custom_date_format(changeset, :custom_start_date)
        |> validate_custom_date_format(:custom_end_date)
      _ ->
        add_error(changeset, :custom_dates, "Both custom start and end dates must be provided")
    end
  end

  defp validate_custom_date_format(changeset, field) do
    case get_field(changeset, field) do
      %{"year" => _, "month" => _, "day" => _} -> changeset
      _ -> add_error(changeset, field, "must contain year, month, and day")
    end
  end
end
