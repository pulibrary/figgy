# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "catalog/_resource_attributes_default.html.erb" do
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
      allow(view).to receive(:document).and_return(solr_document)
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
  context 'when given an Ephemera Folder' do
    let(:folder) { FactoryGirl.create_for_repository(:ephemera_folder, date_range: DateRange.new(start: "1989", end: "2017")) }
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
      expect(rendered).to have_selector 'li.rendered_date_range', text: '1989-2017'
    end
  end
end
