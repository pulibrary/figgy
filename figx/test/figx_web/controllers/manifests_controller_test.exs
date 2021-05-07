defmodule FigxWeb.ManifestsControllerTest do
  use FigxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
  end

  describe "GET /manifest/id" do
    test "returns a collection manifest", %{conn: conn} do
      resource_id = "597edce8-3a2f-41cd-be2b-182dae7b9a8f"
      conn = get(conn, "/manifest/#{resource_id}")
      json = json_response(conn, 200)

      assert json["@id"] ==
               "http://localhost:4002/collections/597edce8-3a2f-41cd-be2b-182dae7b9a8f/manifest"

      assert json["@context"] == "http://iiif.io/api/presentation/2/context.json"
      assert json["@type"] == "sc:Collection"
      assert json["label"] == ["Test Collection"]
      assert json["description"] == ["Test Description"]
      assert json["metadata"] == [%{"label" => "Exhibit", "value" => ["studentperf"]}]
    end

    test "returns 400 for a resource manifest request", %{conn: conn} do
      resource_id = "abd5f5a2-7caa-435a-924e-d5982b0a6260"
      conn = get(conn, "/manifest/#{resource_id}")
      assert conn.status == 400
    end
  end
end
