# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/show.html.erb" do
  context 'when given a new ScannedResource instance' do
    let(:scanned_resource) do
      FactoryGirl.create_for_repository(:scanned_resource,
                                        title: 'test title1',
                                        label: 'test label',
                                        actor: 'test person',
                                        sort_title: 'test title2',
                                        portion_note: 'test value1',
                                        rights_statement: 'test statement',
                                        call_number: 'test value2',
                                        edition: 'test edition',
                                        nav_date: 'test date')
    end
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: scanned_resource) }
    let(:collection) { FactoryGirl.create_for_repository(:collection) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      Timecop.freeze(Time.zone.local(1990))
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end
    it "renders all available attributes" do
      # Title
      expect(rendered).to have_content "test title1"

      expect(rendered).to have_selector "#attributes h2", text: "Attributes"

      # Label
      expect(rendered).to have_selector "th", text: "Label"
      expect(rendered).to have_content "test label"

      # Actor
      expect(rendered).to have_selector "th", text: "Actor"
      expect(rendered).to have_content "test person"

      # Sorting Title
      expect(rendered).not_to have_selector "th", text: "Sort Title"
      expect(rendered).not_to have_content "test title2"

      # Portion Note
      expect(rendered).to have_selector "th", text: "Portion Note"
      expect(rendered).to have_content "test value1"

      # Call Number
      expect(rendered).to have_selector "th", text: "Call Number"
      expect(rendered).to have_content "test value2"

      # Edition
      expect(rendered).to have_selector "th", text: "Edition"
      expect(rendered).to have_content "test edition"

      # Nav Date
      expect(rendered).not_to have_selector "th", text: "Nav Date"
      expect(rendered).not_to have_content "test date"

      # Model name
      expect(rendered).to have_selector "th", text: "Model"
      expect(rendered).to have_content "ScannedResource"

      # Date Uploaded
      expect(rendered).to have_selector "th", text: "Date Uploaded"
      expect(rendered).to have_selector ".created_at", text: "01/01/90 12:00:00 AM UTC"

      # Date Modified
      expect(rendered).to have_selector "th", text: "Date Modified"
      expect(rendered).to have_selector ".updated_at", text: "01/01/90 12:00:00 AM UTC"
    end
  end

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
      stub_blacklight_views
      render
    end
    it "renders all available attributes" do
      expect(rendered).to have_content scanned_resource.primary_imported_metadata.title.to_sentence
      expect(rendered).to have_content "Ars minor [fragment]."

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
      expect(rendered).not_to have_selector "th", text: "Description"
      expect(rendered).not_to have_content "WHS fragment is parts of 2 leaves (ff. 2.7, Schwenke 6,1-9,6; 10,2-12,5; 22,1-23,21; 24,2-36) of a 27-line edition; vellum; Type 5."

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

  context 'when the ScannedResource has members' do
    let(:child) { FactoryGirl.create_for_repository(:scanned_resource, title: 'vol1', rights_statement: 'x') }
    let(:parent) { FactoryGirl.create_for_repository(:scanned_resource, title: 'Mui', rights_statement: 'y', member_ids: [child.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Members'
      expect(rendered).to have_selector 'td', text: 'vol1'
      expect(rendered).to have_selector 'span.label-success', text: 'Open'
      expect(rendered).not_to have_link href: solr_document_path(child)
      expect(rendered).to have_link 'View', href: parent_solr_document_path(parent, "id-#{child.id}")
      expect(rendered).to have_link 'Edit', href: edit_scanned_resource_path(child.id)
    end
  end

  context "when it's a project with boxes" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_project, member_ids: [child.id]) }
    let(:child) { FactoryGirl.create_for_repository(:ephemera_box) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Boxes'
      expect(rendered).to have_link 'Box 1', href: solr_document_path(id: "id-#{child.id}")
    end
  end

  context "when it's a box with folders" do
    let(:parent) { FactoryGirl.create_for_repository(:ephemera_box, member_ids: [child.id]) }
    let(:child) { FactoryGirl.create_for_repository(:ephemera_folder) }
    let(:child) { FactoryGirl.create_for_repository(:ephemera_box) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: parent) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end

    it 'shows them' do
      expect(rendered).to have_selector 'h2', text: 'Folders'
    end
  end

  context 'when given a FileSet' do
    let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }
    let(:scanned_resource) { FactoryGirl.create_for_repository(:scanned_resource, files: [file]) }
    let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
    let(:fileset) { scanned_resource.member_ids.map { |id| solr.query_service.find_by(id: id) }.first }
    let(:document) { solr.resource_factory.from_resource(resource: fileset) }
    let(:solr_document) { SolrDocument.new(document) }
    before do
      assign :document, solr_document
      allow(view).to receive(:has_search_parameters?).and_return(false)
      stub_blacklight_views
      render
    end

    it 'shows technical metadata' do
      expect(rendered).to have_selector 'li.internal_resource', text: 'FileSet'
      expect(rendered).to have_selector 'li.height', text: '287'
      expect(rendered).to have_selector 'li.width', text: '200'
      expect(rendered).to have_selector 'li.mime_type', text: 'image/tiff'
      expect(rendered).to have_selector 'li.size', text: '196882'
      expect(rendered).to have_selector 'li.md5', text: '2a28fb702286782b2cbf2ed9a5041ab1'
      expect(rendered).to have_selector 'li.sha1', text: '1b95e65efc3aefeac1f347218ab6f193328d70f5'
      expect(rendered).to have_selector 'li.sha256', text: '547c81b080eb2d7c09e363a670c46960ac15a6821033263867dd59a31376509c'
    end
  end
end
