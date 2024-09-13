defmodule TimeTracker.Calendar.CalendarSystem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "calendar_systems" do
    field :name, :string
    field :week_length, :integer
    field :day_one, :date
    field :months, {:array, :map}
    field :day_names, {:array, :string}
    field :leap_year_rule, :map
    field :extra_days_distribution, {:array, :map}
    field :leap_month_rule, :map
    field :leap_month, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(calendar_system, attrs) do
    calendar_system
    |> cast(attrs, [:name, :week_length, :day_one, :months, :day_names, :leap_year_rule, :extra_days_distribution, :leap_month_rule, :leap_month])
    |> validate_required([:name, :week_length, :day_one, :months, :day_names, :leap_year_rule, :extra_days_distribution, :leap_month_rule, :leap_month])
    |> validate_number(:week_length, greater_than: 0)
    |> validate_months()
  end

  defp validate_months(changeset) do
    validate_change(changeset, :months, fn _, months ->
      if Enum.all?(months, &valid_month?/1) do
        []
      else
        [months: "invalid month configuration"]
      end
    end)
  end

  defp valid_month?(%{"name" => name, "length" => length}) when is_binary(name) and is_integer(length) and length > 0, do: true
  defp valid_month?(_), do: false
end
