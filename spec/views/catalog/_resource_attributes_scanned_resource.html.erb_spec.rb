# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_resource_attributes_scanned_resource.html.erb" do
  context "when given a ScannedResource solr document" do
    let(:scanned_resource) do
      FactoryGirl.create_for_repository(:scanned_resource,
                                        imported_metadata: [
                                          {
                                            title: "Ars minor [fragment].",
                                            language: "lat",
                                            creator: "Donatus, Aelius",
                                            call_number: "114.14",
                                            extent: "2 partial leaves ; 20 x 14.8 cm.",
                                            format: "Book",
                                            type: "Early works to 1500",
                                            description: "WHS fragment is parts of 2 leaves (ff. 2.7, Schwenke 6,1-9,6; 10,2-12,5; 22,1-23,21; 24,2-36) of a 27-line edition; vellum; Type 5.",
                                            publisher: "[Netherlands : Prototypography, about 1465-1480].",
                                            subject: [
                                              "Latin language—Grammar—Early works to 1500",
                                              "Type and type-founding—Specimens"
                                            ],
                                            sort_title: "Ars minor [fragment].",
                                            former_owner: [
                                              "Hodgkin, John Eliot"
                                            ],
                                            bookseller: [
                                              "Maggs Bros"
                                            ],
                                            author: "Donatus, Aelius",
                                            created: ['1465-01-01T00:00:00Z', '1480-12-31T23:59:59Z'],
                                            date: "1465-1480",
                                            identifier: "http://arks.princeton.edu/ark:/88435/5m60qr98h"
                                          }
                                        ],
                                        member_of_collection_ids: [collection.id],
                                        holding_location: RDF::URI('https://bibdata.princeton.edu/locations/delivery_locations/1'))
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource) }
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
      expect(rendered).to have_content "lat"

      # Creator
      expect(rendered).to have_selector "th", text: "Creator"
      expect(rendered).to have_content "Donatus, Aelius"

      # Call Number
      expect(rendered).to have_selector "th", text: "Call Number"
      expect(rendered).to have_content "114.14"

      # Extent
      expect(rendered).to have_selector "th", text: "Extent"
      expect(rendered).to have_content "2 partial leaves ; 20 x 14.8 cm."

      # Type
      expect(rendered).to have_selector "th", text: "Type"
      expect(rendered).to have_content "Early works to 1500"

      # Description
      expect(rendered).to have_selector "th", text: "Description"
      expect(rendered).to have_content "WHS fragment is parts of 2 leaves (ff. 2.7, Schwenke 6,1-9,6; 10,2-12,5; 22,1-23,21; 24,2-36) of a 27-line edition; vellum; Type 5."

      # Publisher
      expect(rendered).to have_selector "th", text: "Publisher"
      expect(rendered).to have_content "[Netherlands : Prototypography, about 1465-1480]."

      # Subject
      expect(rendered).to have_selector "th", text: "Subject"
      expect(rendered).to have_content "Latin language—Grammar—Early works to 1500"
      expect(rendered).to have_content "Type and type-founding—Specimens"

      # Sort Title
      expect(rendered).not_to have_selector "th", text: "Sort Title"

      # Former Owner
      expect(rendered).to have_selector "th", text: "Former Owner"
      expect(rendered).to have_content "Hodgkin, John Eliot"

      # Bookseller
      expect(rendered).to have_selector "th", text: "Bookseller"
      expect(rendered).to have_content "Maggs Bros"

      # Author
      expect(rendered).to have_selector "th", text: "Author"
      expect(rendered).to have_content "Donatus, Aelius"

      # Date
      expect(rendered).to have_selector "th", text: "Date"
      expect(rendered).to have_content "1465-1480"

      # Identifier
      expect(rendered).to have_selector "th", text: "Identifier"
      expect(rendered).to have_content "http://arks.princeton.edu/ark:/88435/5m60qr98h"

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
