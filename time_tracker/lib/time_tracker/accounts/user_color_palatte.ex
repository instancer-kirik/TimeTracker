# lib/time_tracker/calendar/user_color_palette.ex
defmodule TimeTracker.Accounts.UserColorPalette do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_color_palettes" do
    field :name, :string  # Add this line
    field :colors, {:array, :string}
    belongs_to :user, TimeTracker.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(user_color_palette, attrs) do
    user_color_palette
    |> cast(attrs, [:name, :colors, :user_id])  # Update this line
    |> validate_required([:name, :colors, :user_id])  # Update this line
    |> validate_length(:colors, max: 10)  # Limit to 10 colors, adjust as needed
  end
end
