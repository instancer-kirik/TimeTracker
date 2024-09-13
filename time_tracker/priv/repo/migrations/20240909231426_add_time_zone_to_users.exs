defmodule TimeTracker.Repo.Migrations.AddTimeZoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :time_zone, :string, default: "Etc/UTC"
    end
  end
end
