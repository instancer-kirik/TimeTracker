defmodule TimeTrackerWeb.DayDataLiveTest do
  use TimeTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import TimeTracker.CalendarFixtures

  @create_attrs %{date: "2024-09-07", mood: "some mood", notes: "some notes"}
  @update_attrs %{date: "2024-09-08", mood: "some updated mood", notes: "some updated notes"}
  @invalid_attrs %{date: nil, mood: nil, notes: nil}

  defp create_day_data(_) do
    day_data = day_data_fixture()
    %{day_data: day_data}
  end

  describe "Index" do
    setup [:create_day_data]

    test "lists all day_datas", %{conn: conn, day_data: day_data} do
      {:ok, _index_live, html} = live(conn, ~p"/day_datas")

      assert html =~ "Listing Day datas"
      assert html =~ day_data.mood
    end

    test "saves new day_data", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/day_datas")

      assert index_live |> element("a", "New Day data") |> render_click() =~
               "New Day data"

      assert_patch(index_live, ~p"/day_datas/new")

      assert index_live
             |> form("#day_data-form", day_data: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#day_data-form", day_data: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/day_datas")

      html = render(index_live)
      assert html =~ "Day data created successfully"
      assert html =~ "some mood"
    end

    test "updates day_data in listing", %{conn: conn, day_data: day_data} do
      {:ok, index_live, _html} = live(conn, ~p"/day_datas")

      assert index_live |> element("#day_datas-#{day_data.id} a", "Edit") |> render_click() =~
               "Edit Day data"

      assert_patch(index_live, ~p"/day_datas/#{day_data}/edit")

      assert index_live
             |> form("#day_data-form", day_data: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#day_data-form", day_data: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/day_datas")

      html = render(index_live)
      assert html =~ "Day data updated successfully"
      assert html =~ "some updated mood"
    end

    test "deletes day_data in listing", %{conn: conn, day_data: day_data} do
      {:ok, index_live, _html} = live(conn, ~p"/day_datas")

      assert index_live |> element("#day_datas-#{day_data.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#day_datas-#{day_data.id}")
    end
  end

  describe "Show" do
    setup [:create_day_data]

    test "displays day_data", %{conn: conn, day_data: day_data} do
      {:ok, _show_live, html} = live(conn, ~p"/day_datas/#{day_data}")

      assert html =~ "Show Day data"
      assert html =~ day_data.mood
    end

    test "updates day_data within modal", %{conn: conn, day_data: day_data} do
      {:ok, show_live, _html} = live(conn, ~p"/day_datas/#{day_data}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Day data"

      assert_patch(show_live, ~p"/day_datas/#{day_data}/show/edit")

      assert show_live
             |> form("#day_data-form", day_data: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#day_data-form", day_data: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/day_datas/#{day_data}")

      html = render(show_live)
      assert html =~ "Day data updated successfully"
      assert html =~ "some updated mood"
    end
  end
end
