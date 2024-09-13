defmodule TimeTracker.Repo.Migrations.AddUserLabelToDayDatas do
  use Ecto.Migration

  def change do
    alter table(:day_datas) do
      add :user_label_id, references(:user_labels, on_delete: :nilify_all)
    end

    create index(:day_datas, [:user_label_id])
  end
end
