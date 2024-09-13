defmodule TimeTracker.Repo.Migrations.CreateDayDataLabels do
  use Ecto.Migration

  def change do
    create table(:day_data_labels, primary_key: false) do
      add :day_data_id, references(:day_datas, on_delete: :delete_all), primary_key: true
      add :user_label_id, references(:user_labels, on_delete: :delete_all), primary_key: true
    end

    create index(:day_data_labels, [:day_data_id])
    create index(:day_data_labels, [:user_label_id])
    create unique_index(:day_data_labels, [:day_data_id, :user_label_id])
  end
end
