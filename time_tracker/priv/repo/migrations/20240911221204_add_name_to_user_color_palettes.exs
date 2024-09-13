defmodule TimeTracker.Repo.Migrations.AddNameToUserColorPalettes do
  use Ecto.Migration

  def change do
    alter table(:user_color_palettes) do
      add :name, :string  # Add the name column
    end
  end
end
