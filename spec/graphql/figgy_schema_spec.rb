# frozen_string_literal: true
require "rails_helper"

RSpec.describe FiggySchema do
  # You can override `context` or `variables` in
  # more specific scopes
  let(:context) { {} }
  let(:variables) { {} }
  # Call `result` to execute the query
  let(:result) do
    res = described_class.execute(
      query_string,
      context: context,
      variables: variables
    )
    # Print any errors
    pp res if res["errors"]
    res
  end

  describe "resource query" do
    # provide a query string for `result`
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "individuals") }
    let(:id) { scanned_resource.id }
    let(:query_string) { %|{ resource(id: "#{id}") { viewingHint } }| }

    it "returns a viewing hint" do
      # calling `result` executes the query
      expect(result["data"]["resource"]["viewingHint"]).to eq("individuals")
    end
  end
end
