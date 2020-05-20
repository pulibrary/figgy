# frozen_string_literal: true
require "rails_helper"

RSpec.describe OaiController do
  describe "ListRecords" do
    context "when requesting a Cicognara set" do
      it "returns all the Cicognara item MarcXML" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "8543429", content_type: "application/marcxml+xml")
        FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429", import_metadata: true)

        get :index, params: { "verb" => "ListRecords", "set" => "cico", "metadataPrefix" => "marc21" }

        result = Nokogiri::XML(response.body).remove_namespaces!
        records = result.xpath("//ListRecords/record")
        expect(records.length).to eq 1
      end
    end
    context "when there's no data" do
      it "works" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "8543429", content_type: "application/marcxml+xml")
        FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429", import_metadata: true)

        get :index, params: { "verb" => "ListRecords", "set" => "nonexistent", "metadataPrefix" => "marc21" }

        result = Nokogiri::XML(response.body).remove_namespaces!
        records = result.xpath("//ListRecords/record")
        expect(records.length).to eq 0
      end
    end
  end

  describe "GetRecord" do
    it "returns a specific item" do
      stub_ezid(shoulder: "99999/fk4", blade: "8543429")
      stub_bibdata(bib_id: "8543429")
      stub_bibdata(bib_id: "8543429", content_type: "application/marcxml+xml")
      resource = FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "8543429")

      get :index, params: { "verb" => "GetRecord", "metadataPrefix" => "marc21", identifier: "oai:figgy:#{resource.id}" }

      result = Nokogiri::XML(response.body).remove_namespaces!
      records = result.xpath("//GetRecord/record")
      expect(records.length).to eq 1
      expect(result.xpath("//request").text).to eq "http://www.example.com/oai"
    end
  end

  describe "ListSets" do
    it "returns all collections" do
      FactoryBot.create_for_repository(:collection, slug: "cico")

      get :index, params: { "verb" => "ListSets" }

      result = Nokogiri::XML(response.body).remove_namespaces!
      records = result.xpath("//ListSets/set/setSpec").map(&:text)
      expect(records).to contain_exactly "cico"
    end
    context "when requesting a Cicognara set" do
      it "returns all the Cicognara item MarcXML" do
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "8543429", content_type: "application/marcxml+xml")
        FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429", import_metadata: true)

        get :index, params: { "verb" => "ListRecords", "set" => "cico", "metadataPrefix" => "marc21" }

        result = Nokogiri::XML(response.body).remove_namespaces!
        records = result.xpath("//ListRecords/record")
        expect(records.length).to eq 1
      end

      it "can page" do
        allow(OaiProvider::ValkyrieProviderModel).to receive(:limit).and_return(2)
        collection = FactoryBot.create_for_repository(:collection, slug: "cico")
        source_metadata_identifier = "8543429"
        stub_ezid(shoulder: "99999/fk4", blade: source_metadata_identifier)
        stub_bibdata(bib_id: source_metadata_identifier)
        stub_bibdata(bib_id: source_metadata_identifier, content_type: "application/marcxml+xml")
        5.times do
          FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: source_metadata_identifier, import_metadata: true)
        end

        get :index, params: { "verb" => "ListRecords", "set" => "cico", "metadataPrefix" => "marc21" }
        result = Nokogiri::XML(response.body).remove_namespaces!
        token = result.xpath("//resumptionToken").text

        get :index, params: { "verb" => "ListRecords", "resumptionToken" => token }
        result = Nokogiri::XML(response.body).remove_namespaces!
        token = result.xpath("//resumptionToken").text
        expect(token.split(":").last).to eq "2"
      end
    end
  end
end
