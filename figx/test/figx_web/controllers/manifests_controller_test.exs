defmodule FigxWeb.ManifestsControllerTest do
  use FigxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
  end

  test "GET /manifest/id", %{conn: conn} do
    resource_id = "597edce8-3a2f-41cd-be2b-182dae7b9a8f"
    conn = get(conn, "/manifest/#{resource_id}")
    json = json_response(conn, 200)
    assert json["id"] == "597edce8-3a2f-41cd-be2b-182dae7b9a8f"
    assert json["label"] == ["Test Collection"]
  end
end
