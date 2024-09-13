defmodule TimeTracker.Repo.Migrations.AddDayNamesToCalendarSystems do
  use Ecto.Migration

  def change do
    alter table(:calendar_systems) do
      add :day_names, {:array, :string}
    end
  end
end
