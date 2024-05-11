# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#facet_search_url" do
    it "provides a link to a search result page faceted by collection" do
      field = "member_of_collection_titles_ssim"
      value = "The Sid Lapidus '59 Collection on Liberty and the American Revolution"
      result = "/?f%5Bmember_of_collection_titles_ssim%5D%5B%5D=The+Sid+Lapidus+%2759+Collection+on+Liberty+and+the+American+Revolution"
      expect(helper.facet_search_url(field: field, value: value)).to eq result
    end
  end

  describe "#resource_attribute_value" do
    context "with a regular attribute value" do
      it "returns the value" do
        expect(helper.resource_attribute_value(:description, "A description")).to eq("A description")
      end
    end

    context "with a monogram reference" do
      let(:monogram) { FactoryBot.create_for_repository(:numismatic_monogram) }

      it "returns a link to the monogram" do
        value = helper.resource_attribute_value(:decorated_numismatic_monograms, monogram.decorate)
        expect(value).to include("href", monogram.id.to_s, monogram.title.first)
      end
    end

    context "with a member_of_collections attribute" do
      let(:title) { "My Collection" }
      let(:collection) { FactoryBot.create_for_repository(:collection, title: title) }

      it "returns a link to the collection" do
        value = helper.resource_attribute_value(:member_of_collections, collection.decorate)
        expect(value).to include("href", collection.id.to_s, title)
      end
    end
  end

  describe "#build_authorized_link" do
    context "when given a Playlist with an auth token" do
      it "returns a link to the viewer" do
        playlist = FactoryBot.create_for_repository(:playlist, auth_token: "banana")
        doc = instance_double("SolrDocument")
        allow(doc).to receive(:resource).and_return(playlist)
        assign(:document, doc)

        value = helper.build_authorized_link

        url = "http://test.host/viewer#?manifest=http://test.host/concern/playlists/#{playlist.id}/manifest?auth_token=#{playlist.auth_token}"
        expect(value).to eq(
          %(<a href="#{url}">#{url}</a>)
        )
      end
    end
  end

  describe "#link_back_to_catalog" do
    let(:search_session) do
      {}
    end
    let(:search_state) { instance_double(Blacklight::SearchState) }
    let(:current_search_session) { instance_double(Search) }

    before do
      # This is required to generate the path for the catalog actions
      allow(helper).to receive(:search_action_path).and_return(search_catalog_path)

      allow(helper).to receive(:search_session).and_return(search_session)
      allow(search_state).to receive(:to_hash).and_return({})
      allow(search_state).to receive(:reset).and_return(search_state)
      allow(helper).to receive(:search_state).and_return(search_state)
      allow(current_search_session).to receive(:query_params).and_return({})
      allow(helper).to receive(:current_search_session).and_return(current_search_session)
    end

    it "generates the search URL from a record" do
      expect(helper.link_back_to_catalog).to eq '<a href="/catalog">Back to Search</a>'
    end

    context "when the search session contained parameters for per-page result limits" do
      # Scope objects are just anonymous objects
      let(:scope) { double }
      let(:blacklight_config) { Blacklight::Configuration.new }
      let(:search_session) do
        {
          "per_page" => 10,
          "counter" => 1,
          "page" => 1
        }
      end

      before do
        allow(helper).to receive(:url_for)
        allow(helper).to receive(:blacklight_config).and_return(blacklight_config)

        helper.link_back_to_catalog
      end

      it "generates the search URL with query parameters" do
        expect(helper).to have_received(:url_for).with(page: 1, q: "")
      end
    end

    context "when the query is async" do
      # Scope objects are just anonymous objects
      let(:scope) { double }
      let(:blacklight_config) { Blacklight::Configuration.new }
      let(:search_session) do
        {
          "id" => 16,
          "counter" => 1,
          "page" => 1
        }
      end

      it "generates the search URL from a record" do
        allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
        allow(current_search_session).to receive(:query_params).and_return("async" => "true")

        expect(helper.link_back_to_catalog).to eq '<a href="/catalog">Back to Search</a>'
      end
    end
  end

  describe "#universal_viewer_path" do
    let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }

    it "generates the path for the embedded UV partial" do
      expect(helper.universal_viewer_path(resource)).to eq "/viewer#?manifest=http://test.host/concern/scanned_resources/#{resource.id}/manifest"
    end
  end

  describe "#fileset_download_path" do
    let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [file_meta]) }
    let(:file_meta) { FileMetadata.new(id: "1234", use: ::PcdmUse::OriginalFile, mime_type: "application/pdf") }

    it "points to the original pdf" do
      expect(helper.fileset_download_path(file_set)).to eq "/downloads/#{file_set.id}/file/1234"
    end
  end

  describe "#figgy_pdf_path" do
    context "when the resource supports pdf generation" do
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }

      it "points to the figgy-generated pdf" do
        expect(helper.figgy_pdf_path(resource)).to eq "/concern/scanned_resources/#{resource.id}/pdf"
      end
    end

    context "when the resource does not support pdf generation" do
      let(:resource) { FactoryBot.create_for_repository(:collection) }

      it "is nil" do
        expect(helper.figgy_pdf_path(resource)).to be_nil
      end
    end
  end
end
