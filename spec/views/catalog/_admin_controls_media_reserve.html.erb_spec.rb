# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_admin_controls_media_reserve" do
  let(:media_reserve) { FactoryBot.create_for_repository(:media_reserve, member_ids: file_set.id) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: media_reserve) }
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
      expect(rendered).to have_selector "a[href='#{playlists_path(media_reserve_id: media_reserve.id.to_s)}'][data-method=post]", text: "Create Playlist"
    end
  end
end
