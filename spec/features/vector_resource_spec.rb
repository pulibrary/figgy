# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Vector Resource" do
  let(:user) { FactoryBot.create(:admin) }

  before do
    stub_catalog(bib_id: "99100017893506421")
    sign_in user
  end

  scenario "creating a new resource and viewing geoblacklight document", js: true do
    visit new_vector_resource_path

    fill_in "vector_resource_source_metadata_identifier", with: "99100017893506421"
    fill_in "Local identifier", with: "local_id"
    click_button "Save"

    qs = ChangeSetPersister.default.query_service
    id = qs.find_all_of_model(model: VectorResource).first.id.to_s

    visit geoblacklight_vector_resource_path(id: id)

    # GeoBlacklight document does not contain references with an empty string (`[""]`)
    expect(page).not_to have_content("http://www.opengis.net/def/serviceType/ogc/wfs")
    expect(page).not_to have_content("http://www.opengis.net/def/serviceType/ogc/wms")
  end
end
