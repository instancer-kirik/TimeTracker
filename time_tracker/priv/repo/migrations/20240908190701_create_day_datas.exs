defmodule TimeTracker.Repo.Migrations.CreateDayDatas do
  use Ecto.Migration

  def change do
    create table(:day_datas) do
      add :date, :date, null: false
      add :mood, :string
      add :notes, :text

      timestamps()
    end

    #create index(:day_datas, [:date]) #if you frequently query across all users for a specific date range


  end
end
