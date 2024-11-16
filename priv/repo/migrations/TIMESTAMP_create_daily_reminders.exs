defmodule TimeTracker.Repo.Migrations.CreateDailyReminders do
  use Ecto.Migration

  def change do
    create table(:daily_reminders) do
      add :title, :string, null: false
      add :description, :text
      add :time_of_day, :time, null: false
      add :active, :boolean, default: true, null: false
      add :days_of_week, {:array, :integer}, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :calendar_system_id, references(:calendar_systems, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:daily_reminders, [:user_id])
    create index(:daily_reminders, [:calendar_system_id])
  end
end 