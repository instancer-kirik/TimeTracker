defmodule TimeTracker.Repo.Migrations.CreateUserLabels do
  use Ecto.Migration

  def change do
    create table(:user_labels) do
      add :name, :string, null: false
      add :color, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_labels, [:user_id])
    create unique_index(:user_labels, [:name, :user_id])
  end
end
