# frozen_string_literal: true
require "rails_helper"

RSpec.describe OaiController do
  describe "Identify" do
    it "has the correct repository name" do
      get :index, params: { "verb" => "Identify" }
      result = Nokogiri::XML(response.body).remove_namespaces!
      expect(result.xpath("//repositoryName").text).to eq "Princeton University Library"
    end

    it "has an earliest timestamp" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      get :index, params: { "verb" => "Identify" }
      result = Nokogiri::XML(response.body).remove_namespaces!
      expect(result.xpath("//earliestDatestamp").text).to eq resource.updated_at.iso8601
    end

    it "has the correct email address" do
      get :index, params: { "verb" => "Identify" }
      result = Nokogiri::XML(response.body).remove_namespaces!
      expect(result.xpath("//adminEmail").text).to eq "digital-library@princeton.libanswers.com"
    end

    it "gives a sample id in the correct form" do
      get :index, params: { "verb" => "Identify" }
      result = Nokogiri::XML(response.body).remove_namespaces!
      expect(result.xpath("//sampleIdentifier").text).to eq "oai:figgy:fb4ecf51-58c8-4481-8a91-12f05d4729aa"
    end
  end

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

    context "when requesting a Louis-Alexandre Berthier set" do
      it "returns all the resources in oai_dc" do
        collection = FactoryBot.create_for_repository(:collection, slug: "C0022")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        stub_pulfa(pulfa_id: "C0022_c0145")
        FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "C0022_c0145", import_metadata: true)

        get :index, params: { "verb" => "ListRecords", "set" => "C0022", "metadataPrefix" => "oai_dc" }

        result = Nokogiri::XML(response.body).remove_namespaces!
        records = result.xpath("//ListRecords/record")
        expect(records.length).to eq 1
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

    context "when getting an oai_dc / finding aid record" do
      it "returns the record with desired fields populated" do
        collection = FactoryBot.create_for_repository(:collection, slug: "C0022")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        stub_pulfa(pulfa_id: "C0022_c0145")
        resource = FactoryBot.create_for_repository(:complete_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "C0022_c0145", import_metadata: true)

        get :index, params: { "verb" => "GetRecord", "identifier" => "oai:figgy:#{resource.id}", "metadataPrefix" => "oai_dc" }

        result = Nokogiri::XML(response.body).remove_namespaces!
        records = result.xpath("//GetRecord/record")
        expect(records.length).to eq 1
        expect(result.xpath("//title").text).to eq "156. Camp à Providence sur le chemin de Boston, le 13 Novembre, 4 miles de l'ancien Camp"
        expect(result.xpath("//creator").text).to eq "Berthier, Louis-Alexandre, 1753-1815."
        expect(result.xpath("//publisher").text).to eq "Berthier, Louis-Alexandre, 1753-1815."
        expect(result.xpath("//date").text).to eq "1-1"
        expect(result.xpath("//rights").text).to eq "No Known Copyright"
      end
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
        allow(OAI::Figgy::ValkyrieProviderModel).to receive(:limit).and_return(2)
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
