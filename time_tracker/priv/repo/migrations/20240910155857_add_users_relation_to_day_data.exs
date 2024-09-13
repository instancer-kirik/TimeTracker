defmodule TimeTracker.Repo.Migrations.AddUsersRelationToDayData do
  use Ecto.Migration

  def change do
    alter table(:day_datas) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create unique_index(:day_datas, [:user_id, :date])
  end
end
#should check when running code out of proper execution context-environment-scope
