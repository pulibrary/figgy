# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Numismatics::Reference", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:reference) { FactoryBot.build(:numismatic_reference) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    sign_in user
    change_set = Numismatics::ReferenceChangeSet.new(reference)
    change_set_persister.save(change_set: change_set)
  end

  describe "pagination" do
    it "is not displayed on top of the add content menu" do
      visit numismatics_references_path
      expect(page).to have_css(".pagination .active > a")
      page.find(:css, "#site-actions > div.btn-group.add-content").click
      expect(page).to have_css("#site-actions > div.btn-group.add-content.open")
      add_content = page.find(:css, "#site-actions > div.btn-group.add-content.open")
      pagination_number = page.find(:css, ".pagination .active > a")
      pagination_z_value = pagination_number.native.style("z-index")
      expect(pagination_z_value).to eq "0"
      expect(add_content.native.style("z-index")).not_to be < pagination_z_value
    end
  end
end
