# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_resource_attributes_default.html.erb" do
  context "when given a FileSet" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
    let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
    let(:fileset) { scanned_resource.member_ids.map { |id| solr.query_service.find_by(id: id) }.first }
    let(:document) { solr.resource_factory.from_resource(resource: fileset) }
    let(:solr_document) { SolrDocument.new(document) }
    with_queue_adapter :inline
    before do
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      allow(view).to receive(:document).and_return(solr_document)
      stub_blacklight_views
      render
    end

    it "shows technical metadata" do
      expect(rendered).to have_selector "li.internal_resource", text: "FileSet"
      expect(rendered).to have_selector "li.height", text: "287"
      expect(rendered).to have_selector "li.width", text: "200"
      expect(rendered).to have_selector "li.mime_type", text: "image/tiff"
      expect(rendered).to have_selector "li.size", text: "196882"
      expect(rendered).to have_selector "li.md5", text: "2a28fb702286782b2cbf2ed9a5041ab1"
      expect(rendered).to have_selector "li.sha1", text: "1b95e65efc3aefeac1f347218ab6f193328d70f5"
      expect(rendered).to have_selector "li.sha256", text: "547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c"
    end
  end
  context "when given a ScannedResource solr document" do
    let(:scanned_resource) do
      FactoryBot.create_for_repository(
        :complete_scanned_resource,
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
            created: ["1465-01-01T00:00:00Z", "1480-12-31T23:59:59Z"],
            date: "1465-1480",
            identifier: "http://arks.princeton.edu/ark:/88435/5m60qr98h"
          }
        ],
        member_of_collection_ids: [collection.id],
        source_metadata_identifier: "991234563506421",
        visibility: false,
        member_ids: [file_set.id],
        holding_location: RDF::URI("https://bibdata.princeton.edu/locations/delivery_locations/1")
      )
    end
    let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: { use: Valkyrie::Vocab::PCDMUse.OriginalFile }) }
    let(:original_file) { instance_double FileMetadata }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource) }
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      Timecop.freeze(Time.zone.local(1990))
      FactoryBot.create(:local_fixity_success, resource_id: file_set.id)
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      allow(view).to receive(:document).and_return(solr_document)
      stub_blacklight_views
      render
    end
    after { Timecop.return }
    it "renders all available attributes" do
      expect(rendered).to have_selector "#attributes h2", text: "Attributes"

      # Source Metadata Identifier
      expect(rendered).to have_selector "th", text: "Source Metadata Identifier"
      expect(rendered).to have_link "991234563506421", href: "https://catalog.princeton.edu/catalog/991234563506421"

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
      expect(rendered).to have_link collection.title.first, href: "/catalog/#{collection.id}"

      # Holding Location
      expect(rendered).to have_selector ".rendered_holding_location", text: "Plasma Physics Library"
      expect(rendered).to have_selector "th", text: "Holding Location"
      expect(rendered).not_to have_selector ".holding_location"
      expect(rendered).not_to have_selector "th", text: "Rendered Holding Location"
    end
  end

  context "when given a ScannedResource with a component id" do
    let(:scanned_resource) do
      FactoryBot.create_for_repository(
        :scanned_resource,
        source_metadata_identifier: "AC044_c0003"
      )
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource) }
    let(:solr_document) { SolrDocument.new(document) }

    before do
      stub_findingaid(pulfa_id: "AC044_c0003")
      assign :document, solr_document
      allow(view).to receive(:document).and_return(solr_document)
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end
    it "provides a link to the finding aid" do
      expect(rendered).to have_selector "th", text: "Source Metadata Identifier"
      expect(rendered).to have_link "AC044_c0003", href: "https://findingaids.princeton.edu/catalog/AC044_c0003"
    end
  end

  context "when given a ScannedMap solr document" do
    let(:scanned_map) do
      FactoryBot.create_for_repository(
        :scanned_map,
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
        member_of_collection_ids: [collection.id]
      )
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_map) }
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      Timecop.freeze(Time.zone.local(1990))
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      allow(view).to receive(:document).and_return(solr_document)
      stub_blacklight_views
      render
    end
    after { Timecop.return }
    it "renders all available attributes, except if supressed" do
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

      # Extent (supressed)
      expect(rendered).not_to have_selector "th", text: "Extent"

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
  context "when given an Ephemera Folder" do
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder, date_range: DateRange.new(start: "1989", end: "2017")) }
    let(:document) { solr.resource_factory.from_resource(resource: folder) }
    let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
    let(:solr_document) { SolrDocument.new(document) }

    before do
      assign :document, solr_document
      allow(view).to receive(:document).and_return(solr_document)
      render
    end

    it "shows the date range" do
      expect(rendered).to have_selector "th", text: "Date Range"
      expect(rendered).to have_selector "li.rendered_date_range", text: "1989-2017"
    end
  end
end
