defmodule TimeTracker.Calendar.DayData do
  use Ecto.Schema
  import Ecto.Changeset
#maybe query the db by users and all user
  schema "day_datas" do
    field :date, :date
    field :mood, :string
    field :notes, :string
    field :label_colors, :map, default: %{}
    belongs_to :user, TimeTracker.Accounts.User
    many_to_many :labels, TimeTracker.Calendar.UserLabel, join_through: "day_data_labels"

    timestamps()
  end

  @doc false
  def changeset(day_data, attrs) do
    day_data
    |> cast(attrs, [:date, :mood, :notes, :label_colors, :user_id])
    |> validate_required([:date, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
