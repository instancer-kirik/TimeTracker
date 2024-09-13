defmodule TimeTracker.Repo.Migrations.AddLabelColorsToDayDatas do
  use Ecto.Migration

  def change do
    alter table(:day_datas) do
      add :label_colors, :map, default: "{}"
    end
  end
end
