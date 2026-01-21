require "rails_helper"

RSpec.feature "Numismatics::Reference", js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:reference) { FactoryBot.build(:numismatic_reference) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  before do
    sign_in user
    change_set = Numismatics::ReferenceChangeSet.new(reference)
    change_set_persister.save(change_set: change_set)
  end

  describe "reference index page" do
    describe "pagination" do
      it "is not displayed on top of the add content menu" do
        11.times do
          FactoryBot.create_for_repository(:numismatic_reference)
        end

        visit numismatics_references_path
        expect(page).to have_css(".pagination .active > a")
        page.click_link("add-content")
        expect(page).to have_css("#site-actions > div.add-content.show")
        pagination_number = page.find(:css, ".pagination .active > a")
        pagination_z_value = pagination_number.native.style("z-index").to_i
        dropdown_menu = page.find("#site-actions .dropdown-menu")
        dropdown_menu_z_value = dropdown_menu.native.style("z-index").to_i
        expect(pagination_z_value).to be < dropdown_menu_z_value
      end
    end
  end

  describe "reference show page", js: true do
    let(:child_reference) { FactoryBot.create_for_repository(:numismatic_reference, title: "Child Reference") }
    let(:reference) { FactoryBot.create_for_repository(:numismatic_reference, member_ids: [child_reference.id]) }
    let(:citation) { Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: reference.id) }

    it "displays member and related resources data tables" do
      FactoryBot.create_for_repository(:numismatic_issue, numismatic_citation: citation)
      FactoryBot.create_for_repository(:coin, numismatic_citation: citation)

      visit solr_document_path(id: reference.id)
      expect(page).to have_text("Child Reference")
      expect(page).to have_css("#child_numismatic_reference_detach_button")
      expect(page).to have_css("#child_numismatic_reference_attach_button")
      expect(page).to have_text("Issue: 1")
      expect(page).to have_text("Coin: 1")
    end

    describe "pagination behavior of data tables" do
      context "when there are not multiple pages of related resources" do
        it "does not display paginator" do
          visit solr_document_path(id: reference.id)
          expect(page).not_to have_css("ul.pagination")
        end
      end

      context "when there are multiple pages of related resources" do
        before do
          11.times do
            FactoryBot.create_for_repository(:numismatic_issue, numismatic_citation: citation)
          end
        end

        it "does display paginator" do
          visit solr_document_path(id: reference.id)
          expect(page).to have_css("ul.pagination")
        end
      end
    end
  end
end
