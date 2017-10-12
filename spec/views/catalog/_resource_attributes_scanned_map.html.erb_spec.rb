# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_resource_attributes_scanned_map.html.erb" do
  context "when given a ScannedMap solr document" do
    let(:scanned_map) do
      FactoryGirl.create_for_repository(:scanned_map,
                                        imported_metadata: [
                                          {
                                            title: "Map of The British Cameroons",
                                            language: "eng",
                                            creator: "Nigeria. Survey Department",
                                            call_number: "G8731.F7 1927 .C6",
                                            extent: [
                                              "Scale 1:3,000,000 (E 8°33ʹ00ʹʹ--E 14°37ʹ00ʹʹ/N 12°30ʹ00ʹʹ--N 3°53ʹ24ʹʹ).",
                                              "1 map : black and white ; 40 x 26 cm"
                                            ],
                                            format: "Map",
                                            type: "Maps",
                                            description: [
                                              "Map shows the Cameroons under the British administration were divided by a strech of approximately 45 miles into north and south by the Benue River.",
                                              "Map shows area administered by the Residents of Bornu, Yola, and Muri provinces.",
                                              "Original map is filed in the Map/Geospatial Center, map reproduction is attached to companion volume.",
                                              "Copy 2: \"R. O,1007\" ; \"928.10531.A633.1125.9/27.\""
                                            ],
                                            publisher: [
                                              "[Lagos], Nigeria : Survey Department, March 1926.",
                                              "London : His Majesty's Stationery Office, 1927.",
                                              "[London] : Malby & Sons. Lith., 1927."
                                            ],
                                            subject: [
                                              "Administrative and political divisions—Maps",
                                              "Cameroon—Administrative and political divisions",
                                              "Nigeria—Administrative and political divisions",
                                              "Great Britain—Colonies",
                                              "Cameroon—Maps",
                                              "Nigeria—Maps",
                                              "Nigeria",
                                              "Cameroon"
                                            ],
                                            coverage: "northlimit=12.500000; eastlimit=014.620000; southlimit=03.890000; westlimit=008.550000; units=degrees; projection=EPSG:4326",
                                            sort_title: "Map of The British Cameroons / reproduced at Survey Department, Nigeria.",
                                            cartographic_scale: "Scale 1:3,000,000",
                                            spatial: [
                                              "Cameroon",
                                              "Nigeria"
                                            ],
                                            issuing_body: [
                                              "Great Britain. His Majesty's Stationery Office",
                                              "Great Britain. Colonial Office"
                                            ],
                                            cartographer: "Nigeria. Survey Department",
                                            created: "1927-01-01T00:00:00Z/1926-12-31T23:59:59Z",
                                            date: "1927-1926"
                                          }
                                        ],
                                        member_of_collection_ids: [collection.id])
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_map) }
    let(:collection) { FactoryGirl.create_for_repository(:collection) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      Timecop.freeze(Time.zone.local(1990))
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      allow(view).to receive(:document).and_return(solr_document)
      stub_blacklight_views
      render
    end
    it "renders all available attributes" do
      expect(rendered).to have_selector "#attributes h2", text: "Attributes"

      # Language
      expect(rendered).to have_selector "th", text: "Language"
      expect(rendered).to have_content "English"

      # Creator
      expect(rendered).to have_selector "th", text: "Creator"
      expect(rendered).to have_content "Nigeria. Survey Department"

      # Call Number
      expect(rendered).to have_selector "th", text: "Call Number"
      expect(rendered).to have_content "G8731.F7 1927 .C6"

      # Extent
      expect(rendered).to have_selector "th", text: "Extent"
      expect(rendered).to have_content "Scale 1:3,000,000 (E 8°33ʹ00ʹʹ--E 14°37ʹ00ʹʹ/N 12°30ʹ00ʹʹ--N 3°53ʹ24ʹʹ)."

      # Type
      expect(rendered).to have_selector "th", text: "Type"
      expect(rendered).to have_content "Maps"

      # Description
      expect(rendered).to have_selector "th", text: "Description"
      expect(rendered).to have_content "Map shows the Cameroons under the British administration were divided by a strech of approximately 45 miles into north and south by the Benue River."

      # Publisher
      expect(rendered).to have_selector "th", text: "Publisher"
      expect(rendered).to have_content "[Lagos], Nigeria : Survey Department, March 1926."

      # Subject
      expect(rendered).to have_selector "th", text: "Subject"
      expect(rendered).to have_content "Administrative and political divisions—Maps"
      expect(rendered).to have_content "Cameroon—Administrative and political divisions"

      # Sort Title
      expect(rendered).not_to have_selector "th", text: "Sort Title"

      # Date
      expect(rendered).to have_selector "th", text: "Date"
      expect(rendered).to have_content "1927-1926"

      # Model name
      expect(rendered).to have_selector "th", text: "Model"
      expect(rendered).to have_content "ScannedMap"

      # Date Uploaded
      expect(rendered).to have_selector "th", text: "Date Uploaded"
      expect(rendered).to have_selector ".created_at", text: "01/01/90 12:00:00 AM UTC"

      # Date Modified
      expect(rendered).to have_selector "th", text: "Date Modified"
      expect(rendered).to have_selector ".updated_at", text: "01/01/90 12:00:00 AM UTC"

      # Collection
      expect(rendered).to have_selector "th", text: "Collections"
      expect(rendered).to have_selector ".member_of_collections", text: collection.title.first
    end
  end
end
