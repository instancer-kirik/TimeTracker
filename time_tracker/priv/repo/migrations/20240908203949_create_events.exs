defmodule TimeTracker.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string
      add :description, :text
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:user_id])
    create index(:events, [:start_time])
    create index(:events, [:end_time])
    create index(:events, [:user_id, :start_time])

  end
end
