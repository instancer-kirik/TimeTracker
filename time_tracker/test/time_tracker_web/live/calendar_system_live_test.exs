defmodule TimeTrackerWeb.CalendarSystemLiveTest do
  use TimeTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import TimeTracker.CalendarFixtures

  @create_attrs %{name: "some name", week_length: 42, day_one: "2024-09-07"}
  @update_attrs %{name: "some updated name", week_length: 43, day_one: "2024-09-08"}
  @invalid_attrs %{name: nil, week_length: nil, day_one: nil}

  defp create_calendar_system(_) do
    calendar_system = calendar_system_fixture()
    %{calendar_system: calendar_system}
  end

  describe "Index" do
    setup [:create_calendar_system]

    test "lists all calendar_systems", %{conn: conn, calendar_system: calendar_system} do
      {:ok, _index_live, html} = live(conn, ~p"/calendar_systems")

      assert html =~ "Listing Calendar systems"
      assert html =~ calendar_system.name
    end

    test "saves new calendar_system", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/calendar_systems")

      assert index_live |> element("a", "New Calendar system") |> render_click() =~
               "New Calendar system"

      assert_patch(index_live, ~p"/calendar_systems/new")

      assert index_live
             |> form("#calendar_system-form", calendar_system: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#calendar_system-form", calendar_system: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/calendar_systems")

      html = render(index_live)
      assert html =~ "Calendar system created successfully"
      assert html =~ "some name"
    end

    test "updates calendar_system in listing", %{conn: conn, calendar_system: calendar_system} do
      {:ok, index_live, _html} = live(conn, ~p"/calendar_systems")

      assert index_live |> element("#calendar_systems-#{calendar_system.id} a", "Edit") |> render_click() =~
               "Edit Calendar system"

      assert_patch(index_live, ~p"/calendar_systems/#{calendar_system}/edit")

      assert index_live
             |> form("#calendar_system-form", calendar_system: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#calendar_system-form", calendar_system: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/calendar_systems")

      html = render(index_live)
      assert html =~ "Calendar system updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes calendar_system in listing", %{conn: conn, calendar_system: calendar_system} do
      {:ok, index_live, _html} = live(conn, ~p"/calendar_systems")

      assert index_live |> element("#calendar_systems-#{calendar_system.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#calendar_systems-#{calendar_system.id}")
    end
  end

  describe "Show" do
    setup [:create_calendar_system]

    test "displays calendar_system", %{conn: conn, calendar_system: calendar_system} do
      {:ok, _show_live, html} = live(conn, ~p"/calendar_systems/#{calendar_system}")

      assert html =~ "Show Calendar system"
      assert html =~ calendar_system.name
    end

    test "updates calendar_system within modal", %{conn: conn, calendar_system: calendar_system} do
      {:ok, show_live, _html} = live(conn, ~p"/calendar_systems/#{calendar_system}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Calendar system"

      assert_patch(show_live, ~p"/calendar_systems/#{calendar_system}/show/edit")

      assert show_live
             |> form("#calendar_system-form", calendar_system: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#calendar_system-form", calendar_system: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/calendar_systems/#{calendar_system}")

      html = render(show_live)
      assert html =~ "Calendar system updated successfully"
      assert html =~ "some updated name"
    end
  end
end
