defmodule TimeTracker.Repo.Migrations.CreateUserColorPalettes do
  use Ecto.Migration

  def change do
    create table(:user_color_palettes) do
      add :colors, {:array, :string}, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_color_palettes, [:user_id])
  end
end
