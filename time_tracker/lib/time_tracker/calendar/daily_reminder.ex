defmodule TimeTracker.Calendar.DailyReminder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_reminders" do
    field :title, :string
    field :description, :string
    field :time_of_day, :time
    field :active, :boolean, default: true
    field :days_of_week, {:array, :integer}
    belongs_to :user, TimeTracker.Accounts.User
    belongs_to :calendar_system, TimeTracker.Calendar.CalendarSystem

    timestamps(type: :utc_datetime)
  end

  def changeset(daily_reminder, attrs) do
    daily_reminder
    |> cast(attrs, [:title, :description, :time_of_day, :active, :days_of_week, :user_id, :calendar_system_id])
    |> validate_required([:title, :time_of_day, :days_of_week, :user_id])
    |> validate_days_of_week()
  end

  defp validate_days_of_week(changeset) do
    validate_change(changeset, :days_of_week, fn _, days ->
      if Enum.all?(days, &(&1 >= 1 && &1 <= 7)) do
        []
      else
        [days_of_week: "must be between 1 and 7"]
      end
    end)
  end
end 