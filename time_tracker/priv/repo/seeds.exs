# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TimeTracker.Repo.insert!(%TimeTracker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TimeTracker.Repo
alias TimeTracker.Calendar.CalendarSystem

# Gregorian Calendar
Repo.insert!(%CalendarSystem{
  name: "Gregorian",
  week_length: 7,
  day_one: ~D[0001-01-01],
  months: [
    %{"name" => "January", "length" => 31},
    %{"name" => "February", "length" => 28},
    %{"name" => "March", "length" => 31},
    %{"name" => "April", "length" => 30},
    %{"name" => "May", "length" => 31},
    %{"name" => "June", "length" => 30},
    %{"name" => "July", "length" => 31},
    %{"name" => "August", "length" => 31},
    %{"name" => "September", "length" => 30},
    %{"name" => "October", "length" => 31},
    %{"name" => "November", "length" => 30},
    %{"name" => "December", "length" => 31}
  ],
  day_names: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
})

# Ancient Egyptian Calendar
Repo.insert!(%CalendarSystem{
  name: "Ancient Egyptian Calendar",
  week_length: 10,
  day_one: ~D[2023-01-01],
  months: [
    %{"name" => "Thoth", "length" => 30},
    %{"name" => "Phaophi", "length" => 30},
    %{"name" => "Athyr", "length" => 30},
    %{"name" => "Choiak", "length" => 30},
    %{"name" => "Tybi", "length" => 30},
    %{"name" => "Mechir", "length" => 30},
    %{"name" => "Phamenoth", "length" => 30},
    %{"name" => "Pharmuthi", "length" => 30},
    %{"name" => "Pachons", "length" => 30},
    %{"name" => "Payni", "length" => 30},
    %{"name" => "Epiphi", "length" => 30},
    %{"name" => "Mesore", "length" => 30},
    %{"name" => "Epagomenai", "length" => 5}
  ],
  day_names: ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth"]
})

# Fictional 6-day week calendar
Repo.insert!(%CalendarSystem{
  name: "Hexaweek Calendar",
  week_length: 6,
  day_one: ~D[2023-01-01],
  months: [
    %{"name" => "Primum", "length" => 30},
    %{"name" => "Secundum", "length" => 30},
    %{"name" => "Tertium", "length" => 30},
    %{"name" => "Quartum", "length" => 30},
    %{"name" => "Quintum", "length" => 30},
    %{"name" => "Sextum", "length" => 30},
    %{"name" => "Septimum", "length" => 30},
    %{"name" => "Octavum", "length" => 30},
    %{"name" => "Nonum", "length" => 30},
    %{"name" => "Decimum", "length" => 30},
    %{"name" => "Undecimum", "length" => 30},
    %{"name" => "Duodecimum", "length" => 30},
    %{"name" => "Intercalaris", "length" => 5}
  ],
  day_names: ["Primus", "Secundus", "Tertius", "Quartus", "Quintus", "Sextus"]
})
