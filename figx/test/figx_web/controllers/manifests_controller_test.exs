defmodule FigxWeb.ManifestsControllerTest do
  use FigxWeb.ConnCase, async: true

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

      assert json["seeAlso"] == %{
               "@id" =>
                 "http://localhost:4002/catalog/597edce8-3a2f-41cd-be2b-182dae7b9a8f.jsonld",
               "format" => "application/ld+json"
             }

      assert json["rendering"] == %{
               "@id" => "https://arks.princeton.edu/ark:/88435/0p096g241",
               "format" => "text/html"
             }
      assert json["manifests"] == [
        %{
          "@context" => "http://iiif.io/api/presentation/2/context.json",
          "@type" => "sc:Manifest",
          "@id" => "http://localhost:4002/concern/scanned_resources/cad0a459-e520-442d-9139-c338bd60af6f/manifest",
          "label" => [
            "Concert, 2012, April 07"
          ],
          "description" => [
            "A complete program is available in Mendel Music Library."
          ]
        },
        %{
          "@context" => "http://iiif.io/api/presentation/2/context.json",
          "@type" => "sc:Manifest",
          "@id" => "http://localhost:4002/concern/ephemera_folders/02f7dad6-cbaa-47e8-913e-b89bdd16bb17/manifest",
          "label" => [
            "Ephemera Folder"
          ],
          "description" => [
            "I'm ephemera."
          ]
        },
      ]
    end

    test "works for a collection with no ARK", %{conn: conn} do
      resource_id = "868e05da-53b9-483b-8b6b-2d115becce84"
      conn = get(conn, "/manifest/#{resource_id}")
      json = json_response(conn, 200)

      assert json["rendering"] == nil
    end

    test "works for an ephemera project", %{conn: conn} do
      resource_id = "c2062eb2-cf61-412f-be29-43e944ec17e9"
      conn = get(conn, "/manifest/#{resource_id}")
      json = json_response(conn, 200)

      assert json["metadata"] == [%{"label" => "Exhibit", "value" => ["sae"]}]
      assert json["manifests"] == [
        %{
          "@context" => "http://iiif.io/api/presentation/2/context.json",
          "@type" => "sc:Manifest",
          "@id" => "http://localhost:4002/concern/ephemera_folders/02f7dad6-cbaa-47e8-913e-b89bdd16bb17/manifest",
          "label" => [
            "Ephemera Folder"
          ],
          "description" => [
            "I'm ephemera."
          ]
        },
        %{
          "@context" => "http://iiif.io/api/presentation/2/context.json",
          "@type" => "sc:Manifest",
          "@id" => "http://localhost:4002/concern/ephemera_folders/1d1fe5f0-03aa-4f3e-bfb7-97e0cb4fcf68/manifest",
          "label" => [
            "Ephemera Folder2"
          ],
          "description" => [
            "test description"
          ]
        }
      ]

      assert json["seeAlso"] == %{
               "@id" =>
                 "http://localhost:4002/catalog/c2062eb2-cf61-412f-be29-43e944ec17e9.jsonld",
               "format" => "application/ld+json"
             }
    end

    test "returns 400 for a resource manifest request", %{conn: conn} do
      resource_id = "abd5f5a2-7caa-435a-924e-d5982b0a6260"
      conn = get(conn, "/manifest/#{resource_id}")
      assert conn.status == 400
    end
  end
end
