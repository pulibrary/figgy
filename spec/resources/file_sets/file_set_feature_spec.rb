# frozen_string_literal: true

require "rails_helper"

RSpec.feature "File Set" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:file_set) do
    fs = FactoryBot.create_for_repository(:file_set, title: "Page 1")
    adapter.persister.save(resource: fs)
  end
  let(:scanned_resource) do
    res = FactoryBot.create_for_repository(:complete_open_scanned_resource, title: "Wind in the willows", member_ids: [file_set.id])
    adapter.persister.save(resource: res)
  end

  describe "breadcrumbs" do
    before do
      scanned_resource # create it so the parent exists
      sign_in(user)
    end
    it "shows breadcrumbs even when we don't have parent in the url" do
      visit solr_document_path(file_set)

      expect(page).to have_content "Wind in the willows"
    end
  end
end
