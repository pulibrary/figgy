# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/show.html.erb" do
  context "when given a ScannedResource solr document" do
    let(:scanned_resource) do
      FactoryGirl.create_for_repository(:scanned_resource,
                                        imported_metadata: [
                                          {
                                            author: "Shakespeare",
                                            title: "Imported Title"
                                          }
                                        ],
                                        member_of_collection_ids: [collection.id],
                                        holding_location: RDF::URI('https://bibdata.princeton.edu/locations/delivery_locations/1'))
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(scanned_resource) }
    let(:collection) { FactoryGirl.create_for_repository(:collection) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      Timecop.freeze(Time.zone.local(1990))
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end
    it "renders the imported title" do
      expect(rendered).to have_content scanned_resource.primary_imported_metadata.title.to_sentence
    end
    it "renders all available attributes" do
      expect(rendered).to have_content "Imported Title"

      expect(rendered).to have_selector "#attributes h2", text: "Attributes"

      # Author
      expect(rendered).to have_selector "th", text: "Author"
      expect(rendered).to have_content "Shakespeare"

      # Model name
      expect(rendered).to have_selector "th", text: "Model"
      expect(rendered).to have_content "ScannedResource"

      # Date Uploaded
      expect(rendered).to have_selector "th", text: "Date Uploaded"
      expect(rendered).to have_selector ".created_at", text: "01/01/90 12:00:00 AM UTC"

      # Date Modified
      expect(rendered).to have_selector "th", text: "Date Modified"
      expect(rendered).to have_selector ".updated_at", text: "01/01/90 12:00:00 AM UTC"

      # Collection
      expect(rendered).to have_selector "th", text: "Collections"
      expect(rendered).to have_selector ".member_of_collections", text: collection.title.first

      # Holding Location
      expect(rendered).to have_selector "th", text: "Holding Location"
      expect(rendered).to have_selector ".rendered_holding_location", text: "Plasma Physics Library"
    end
  end
end
