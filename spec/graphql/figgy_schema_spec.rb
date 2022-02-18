# frozen_string_literal: true

require "rails_helper"

RSpec.describe FiggySchema do
  # You can override `context` or `variables` in
  # more specific scopes
  let(:context) { {ability: instance_double(Ability, can?: true), change_set_persister: GraphqlController.change_set_persister} }
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
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "individuals") }
    let(:id) { resource.id }
    let(:query_string) { %|{ resource(id: "#{id}") { viewingHint } }| }

    context "when given a scanned resource" do
      it "returns a viewing hint" do
        # calling `result` executes the query
        expect(result["data"]["resource"]["viewingHint"]).to eq("individuals")
      end
    end
    context "when given a file set" do
      let(:resource) { FactoryBot.create_for_repository(:file_set, viewing_hint: "individuals") }
      it "works" do
        expect(result["data"]["resource"]["viewingHint"]).to eq "individuals"
      end
    end
  end
end
