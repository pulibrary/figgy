# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Monogram" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:monogram) do
    mon = FactoryBot.create_for_repository(:numismatic_monogram)
    adapter.persister.save(resource: mon)
  end

  describe "show page" do
    before do
      monogram
      sign_in(user)
    end
    it "does not display the Order Manager button or a button to create a new monogram" do
      visit solr_document_path(monogram)
      expect(page).not_to have_link "Order Manager"
    end
  end

  describe "index page" do
    before do
      sign_in(user)
    end

    it "does not have a link for creating a new monogram" do
      visit numismatics_monograms_path
      expect(page).not_to have_css("a[href='#{new_numismatics_monogram_path}']")
    end
  end
end
