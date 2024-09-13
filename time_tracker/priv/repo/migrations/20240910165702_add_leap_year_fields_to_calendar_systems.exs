defmodule TimeTracker.Repo.Migrations.AddLeapYearFieldsToCalendarSystems do
  use Ecto.Migration

  def change do
    alter table(:calendar_systems) do
      add :leap_year_rule, :string
      add :extra_days_distribution, :string
      add :leap_month_rule, :string
      add :leap_month, :integer
    end
  end
end
