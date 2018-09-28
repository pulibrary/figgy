# frozen_string_literal: true
require "rails_helper"

RSpec.describe GraphqlController do
  describe "#execute" do
    let(:query_string) { %|{ resource(id: "#{id}") { viewingHint } }| }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "individuals") }
    let(:id) { scanned_resource.id }
    let(:user) {}
    before do
      sign_in user if user
    end
    context "when logged in as a staff user" do
      let(:user) { FactoryBot.create(:staff) }
      it "can run a graphql query" do
        post :execute, params: { query: query_string, format: :json }

        expect(response).to be_success
        json_response = JSON.parse(response.body)
        expect(json_response["data"]).to eq(
          "resource" => { "viewingHint" => "individuals" }
        )
      end
      it "doesn't query for parents of FileSets" do
        adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)

        child = FactoryBot.create_for_repository(:file_set)
        parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: child.id, thumbnail_id: child.id)
        allow(adapter.query_service).to receive(:find_inverse_references_by).and_return([parent])
        child_query_string = %|{ resource(id: "#{parent.id}") { members { id }, thumbnail { id, thumbnailUrl, iiifServiceUrl } } }|

        post :execute, params: { query: child_query_string, format: :json }

        expect(response).to be_success
        expect(JSON.parse(response.body)["errors"]).to be_blank
        expect(adapter.query_service).not_to have_received(:find_inverse_references_by)
      end
      it "can support variables set as a JSON string" do
        post :execute, params: { query: query_string, variables: { episode: "bla" }.to_json }
        expect(response).to be_success
      end
      it "can support an empty string for variables" do
        post :execute, params: { query: query_string, variables: "" }
        expect(response).to be_success
      end
      it "will error if given something strange for a variable" do
        expect { post :execute, params: { query: query_string, variables: [1] } }.to raise_error ArgumentError
      end
    end
    context "when not logged in" do
      let(:scanned_resource) { FactoryBot.create_for_repository(:complete_open_scanned_resource, viewing_hint: "individuals") }
      it "can run a graphql query for a public scanned resource" do
        post :execute, params: { query: query_string, format: :json }

        expect(response).to be_success
        json_response = JSON.parse(response.body)
        expect(json_response["data"]).to eq(
          "resource" => { "viewingHint" => "individuals" }
        )
      end
    end
  end
end
