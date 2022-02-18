# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_admin_controls_recording" do
  let(:recording) { FactoryBot.create_for_repository(:recording, member_ids: file_set.id) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: recording) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    assign :document, solr_document
    sign_in user
    render
  end

  context "as an admin" do
    let(:user) { FactoryBot.create(:admin) }
    it "has a link to create a playlist" do
      expect(rendered).to have_selector "a[href='#{playlists_path(recording_id: recording.id.to_s)}'][data-method=post]", text: "Create Playlist"
    end
    context "when it's a descriptive proxy" do
      let(:file_set) { FactoryBot.create_for_repository(:recording) }
      it "does not have a link to create a playlist" do
        expect(rendered).not_to have_link "Create Playlist"
      end
    end
    it "has a link to the structure editor" do
      expect(rendered).to have_link "Structure Manager"
    end
  end
end
