defmodule TimeTracker.Repo.Migrations.CreateCalendarSystems do
  use Ecto.Migration

  def change do
    create table(:calendar_systems) do
      add :name, :string
      add :week_length, :integer
      add :day_one, :date
      add :months, {:array, :map}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:calendar_systems, [:name])
  end
end
