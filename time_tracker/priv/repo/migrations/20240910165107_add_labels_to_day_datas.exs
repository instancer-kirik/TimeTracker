defmodule TimeTracker.Repo.Migrations.AddLabelsToDayDatas do
  use Ecto.Migration

  def change do
    alter table(:day_datas) do
      add :labels, :map
    end
  end
end
