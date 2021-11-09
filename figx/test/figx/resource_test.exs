defmodule Figx.ResourceTest do
  use Figx.DataCase, async: true
  alias Figx.Resource

  describe "description/1" do
    test "no description value returns nil" do
      assert Resource.description(%Resource{}) == nil
    end
  end
end
