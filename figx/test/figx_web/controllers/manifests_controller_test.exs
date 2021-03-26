defmodule FigxWeb.ManifestsControllerTest do
  use FigxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
  end
end
