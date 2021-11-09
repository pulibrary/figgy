defmodule Figx.ManifestTest do
  use Figx.DataCase, async: true
  alias Figx.{Manifest, Resource}

  describe "render_collection_member" do
    test "returns no description key if there isn't a description" do
      output = Manifest.render_collection_member(
        %Resource{
          internal_resource: "ScannedResource",
          metadata: %{
            "title" => ["Title"]
          }
        }
      )

      assert !Map.has_key?(output, "description")
    end
  end
  describe "description/1" do
    test "no description value returns nil" do
      assert Resource.description(%Resource{}) == nil
    end
  end
end
