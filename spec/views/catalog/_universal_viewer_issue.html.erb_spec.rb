# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_universal_viewer_issue.html.erb" do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:coin) do
    FactoryBot.create_for_repository(:coin,
      files: [file],
      counter_stamp: "two small counter-stamps visible as small circles on reverse, without known parallel",
      analysis: "holed at 12 o'clock, 16.73 grams",
      public_note: ["Abraham Usher| John Field| Charles Meredith.", "Black and red ink.", "Visible flecks of mica."],
      private_note: ["was in the same case as coin #8822"],
      find_date: "5/27/1939?",
      find_feature: "Hill A?",
      find_locus: "8-N 40",
      find_number: "2237",
      find_description: "at join of carcares and w. cavea surface",
      die_axis: "6",
      size: "27",
      technique: "Cast",
      weight: "8.26")
  end
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id]) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: issue) }
  let(:solr_document) { SolrDocument.new(document) }
  with_queue_adapter :inline
  before do
    assign :document, solr_document
    allow(view).to receive(:has_search_parameters?).and_return(false)
    allow(view).to receive(:document).and_return(solr_document)
    stub_blacklight_views
    render
  end

  context "when given an Issue with a Coin with a FileSet" do
    it "renders the Universal Viewer" do
      expect(rendered).to have_selector ".uv-container"
    end
  end

  context "when given an Issue with a Coin without a FileSet" do
    let(:coin) do
      FactoryBot.create_for_repository(:coin,
        counter_stamp: "two small counter-stamps visible as small circles on reverse, without known parallel",
        analysis: "holed at 12 o'clock, 16.73 grams",
        public_note: ["Abraham Usher| John Field| Charles Meredith.", "Black and red ink.", "Visible flecks of mica."],
        private_note: ["was in the same case as coin #8822"],
        find_date: "5/27/1939?",
        find_feature: "Hill A?",
        find_locus: "8-N 40",
        find_number: "2237",
        find_description: "at join of carcares and w. cavea surface",
        die_axis: "6",
        size: "27",
        technique: "Cast",
        weight: "8.26")
    end

    it "does not render the Universal Viewer" do
      expect(rendered).not_to have_selector ".uv-container"
    end
  end

  context "when given an Issue without any Coins" do
    let(:issue) { FactoryBot.create_for_repository(:numismatic_issue) }

    it "does not render the Universal Viewer" do
      expect(rendered).not_to have_selector ".uv-container"
    end
  end
end
