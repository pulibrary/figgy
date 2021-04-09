defmodule FigxWeb.ManifestsControllerTest do
  use FigxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
  end

  test "GET /manifest/id", %{conn: conn} do
    resource_id = "hi"
    conn = get(conn, "/manifest/#{resource_id}")
    assert json_response(conn, 200)["id"] =~ "hi"
  end
end
