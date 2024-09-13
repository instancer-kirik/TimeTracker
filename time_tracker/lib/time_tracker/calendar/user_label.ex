defmodule TimeTracker.Calendar.UserLabel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_labels" do
    field :name, :string
    field :color, :string
    belongs_to :user, TimeTracker.Accounts.User
    many_to_many :day_datas, TimeTracker.Calendar.DayData, join_through: "day_data_labels"

    timestamps()
  end

  @doc false
  def changeset(user_label, attrs) do
    user_label
    |> cast(attrs, [:name, :color, :user_id])
    |> validate_required([:name, :color, :user_id])
    |> unique_constraint([:name, :user_id])
  end
end
