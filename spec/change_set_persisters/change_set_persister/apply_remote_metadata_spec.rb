# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::ApplyRemoteMetadata do
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:change_set_class) { ScannedResourceChangeSet }
  let(:blade) { "123456" }
  before do
    stub_ezid(shoulder: "99999/fk4", blade: blade)
    stub_catalog(bib_id: "123456")
  end
  context "when a bibid source_metadata_identifier is set for the first time on a scanned resource" do
    it "applies remote metadata from catalog to an imported metadata resource" do
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "123456")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.", language: :fr)]
      expect(output.primary_imported_metadata.creator).to eq ["Bord, Janet, 1945-"]
      expect(output.primary_imported_metadata.call_number).to eq ["BL980.G7 B66 1982"]
      expect(output.primary_imported_metadata.source_jsonld).not_to be_blank
      # doesn't populate an archival_collection_code field
      expect(output.archival_collection_code).to be_nil
    end

    it "applies electronic locations" do
      stub_catalog(bib_id: "9106203")
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "9106203")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.electronic_locations).to eq [
        LabeledURI.new(uri: RDF::URI("https://arks.princeton.edu/ark:/88435/dcww72bn86z"), label: "Program.")
      ]
    end

    it "doesn't add an identifier that's already on another figgy resource" do
      ark = "ark:/88435/d504rt69g"
      FactoryBot.create_for_repository(:scanned_resource, title: ["Listing of contents"], identifier: ark)

      resource = FactoryBot.build(:scanned_resource, title: [])
      alma_id = "9919685413506421"
      stub_catalog(bib_id: alma_id)
      change_set = ChangeSet.for(resource)
      change_set.validate(source_metadata_identifier: alma_id)
      output = change_set_persister.save(change_set: change_set)

      expect(output.identifier).to be nil
    end
  end

  context "when a source_metadata_identifier is set for the first time on a scanned map" do
    let(:change_set_class) { ScannedMapChangeSet }
    before do
      stub_catalog(bib_id: "10001789")
    end
    it "applies remote metadata from catalog to an imported metadata resource" do
      resource = FactoryBot.build(:scanned_map, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "10001789")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [
        RDF::Literal.new(
          "Cameroons under United Kingdom Trusteeship 1949 / drawn & reproduced by Survey Department, Lagos, Nigeria.",
          language: :eng
        )
      ]
      expect(output.primary_imported_metadata.creator).to eq ["Nigeria. Survey Department"]
      expect(output.primary_imported_metadata.subject).to include "Administrative and political divisions—Maps"
      expect(output.primary_imported_metadata.spatial).to eq ["Cameroon", "Nigeria"]
      expect(output.primary_imported_metadata.coverage).to eq ["northlimit=12.500000; eastlimit=014.620000; southlimit=03.890000; westlimit=008.550000; units=degrees; projection=EPSG:4326"]
      expect(output.identifier).to be nil
    end
    it "doesn't override an existing identifier" do
      resource = FactoryBot.build(:scanned_map, title: [], identifier: ["something"])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "10001789")
      output = change_set_persister.save(change_set: change_set)

      expect(output.identifier).to eq ["something"]
    end
  end

  context "when a source_metadata_identifier is set for the first time on a vector resource" do
    let(:change_set_class) { VectorResourceChangeSet }
    before do
      stub_catalog(bib_id: "9649080")
    end
    it "applies remote metadata from catalog to an imported metadata resource" do
      resource = FactoryBot.build(:vector_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "9649080")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ["Syria 100K Vector Dataset"]
      expect(output.primary_imported_metadata.creator).to eq ["East View Geospatial, Inc"]
    end
  end

  context "when a source metadata identifier is set and then replaced with a title" do
    it "uses the given title" do
      stub_catalog(bib_id: "123456")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456", import_metadata: true)
      expect(resource.title.first.to_s).to eq "Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord."
      change_set = ChangeSet.for(resource)
      change_set.validate(source_metadata_identifier: "", title: "Test")
      output = change_set_persister.save(change_set: change_set)

      expect(output.title).to eq ["Test"]
    end
  end

  context "when a source_metadata_identifier is set for the first time on a raster resource" do
    let(:change_set_class) { RasterResourceChangeSet }
    before do
      stub_catalog(bib_id: "9637153")
    end
    it "applies remote metadata from catalog to an imported metadata resource" do
      resource = FactoryBot.build(:raster_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "9637153")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ["Laos : 1:50,000 scale : Digital Raster graphics (DRGs) of topographic maps : complete coverage of the country (Full GeoTiff); 403 maps."]
      expect(output.primary_imported_metadata.creator).to eq ["Land Info Worldwide Mapping, LLC"]
    end
  end

  context "when a source_metadata_identifier is set and it's from PULFA" do
    let(:blade) { "MC016_c9616" }
    before do
      stub_findingaid(pulfa_id: "MC016_c9616")
    end
    it "applies remote metadata from PULFA" do
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "MC016_c9616")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ['Speech: "... Results of the Eleventh Meeting of the Council of NATO"']
      expect(output.primary_imported_metadata.source_metadata).not_to be_blank
      # populates an archival_collection_code field
      expect(output.archival_collection_code).to eq "MC016"
    end
  end

  context "when a source_metadata_identifier is from PULFA and it's configured to request unpublished content" do
    let(:blade) { "MC016_c9616" }

    it "applies remote metadata from PULFA" do
      allow(Figgy).to receive(:pulfalight_unpublished_token).and_return("1234")
      stub_findingaid(pulfa_id: "MC016_c9616")
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "MC016_c9616")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ['Speech: "... Results of the Eleventh Meeting of the Council of NATO"']
      expect(WebMock).to have_requested(:get, "https://findingaids.princeton.edu/catalog/#{blade}.json?auth_token=1234").at_least_once
    end
  end

  context "when requesting from Alma" do
    it "converts the old ID syntax and tries that too" do
      stub_catalog(bib_id: "123456", status: 404)
      stub_catalog(bib_id: "991234563506421")

      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      expect(change_set.validate(source_metadata_identifier: "123456")).to eq true
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.", language: :fr)]
    end
  end
  context "when a source_metadata_identifier is set and it's from aspace pulfalight" do
    it "applies remote metadata from aspace Pulfalight" do
      stub_findingaid(pulfa_id: "MC001.01_c000001")
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "MC001.01_c000001")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ["Series 1: Reel Contents - American Civil Liberties Union Microfilm"]
      expect(output.primary_imported_metadata.source_metadata).not_to be_blank
      # populates an archival_collection_code field
      expect(output.archival_collection_code).to eq "MC001.01"
    end
  end

  context "when a source_metadata_identifier is set for a collection from PULFA" do
    let(:blade) { "C0652" }
    let(:change_set_class) { ArchivalMediaCollectionChangeSet }
    before do
      stub_findingaid(pulfa_id: "C0652")
    end
    it "applies remote metadata from PULFA" do
      resource = FactoryBot.build(:archival_media_collection, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: blade)
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq ["Emir Rodriguez Monegal Papers"]
      expect(output.primary_imported_metadata.source_metadata).not_to be_blank
    end
  end
  context "when a source_metadata_identifier is set afterwards" do
    it "does not change anything" do
      stub_catalog(bib_id: "123456")
      resource = FactoryBot.create_for_repository(:scanned_resource, title: "Title", source_metadata_identifier: "123456")
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "123456", title: [], refresh_remote_metadata: "0")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to be_blank
    end
    it "refreshes the metadata if it's a different value" do
      stub_catalog(bib_id: "123456")
      stub_catalog(bib_id: "123456789")
      resource = FactoryBot.create_for_repository(:scanned_resource, title: "Title", source_metadata_identifier: "123456")
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "123456789", title: [], refresh_remote_metadata: "0")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).not_to be_blank
    end
  end
  context "when a source_metadata_identifier is set for the first time, and it doesn't exist" do
    before do
      stub_catalog(bib_id: "123456", status: 404)
    end
    it "is marked as invalid" do
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)

      expect(change_set.validate(source_metadata_identifier: "123456")).to eq false
    end
  end
  context "when a source_metadata_identifier is set for the first time, and it doesn't exist from PULFA" do
    before do
      stub_findingaid(pulfa_id: "MC016_c9616", body: "")
    end
    it "is marked as invalid" do
      resource = FactoryBot.build(:scanned_resource, title: [])
      change_set = change_set_class.new(resource)

      expect(change_set.validate(source_metadata_identifier: "MC016_c9616")).to eq false
    end
  end

  context "when a source_metadata_identifier is set afterwards and refresh_remote_metadata is set" do
    before do
      stub_catalog(bib_id: "123456")
    end
    it "applies remote metadata from catalog" do
      resource = FactoryBot.create_for_repository(:scanned_resource, title: "Title", imported_metadata: [{ applicant: "Test" }], source_metadata_identifier: nil)
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "123456", title: [], refresh_remote_metadata: "1")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [RDF::Literal.new("Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.", language: :fr)]
      expect(output.primary_imported_metadata.applicant).to be_blank
      expect(output.source_metadata_identifier).to eq ["123456"]
    end
  end
  context "when a source_metadata_identifier is set for the first time on a scanned map" do
    let(:change_set_class) { ScannedMapChangeSet }
    let(:blade) { "6866386" }

    before do
      stub_catalog(bib_id: "6866386")
    end
    it "applies remote metadata from catalog" do
      resource = FactoryBot.build(:scanned_map, title: [])
      change_set = change_set_class.new(resource)
      change_set.validate(source_metadata_identifier: "6866386")
      output = change_set_persister.save(change_set: change_set)

      expect(output.primary_imported_metadata.title).to eq [
        RDF::Literal.new(
          "Eastern Turkey in Asia. Sheet 16 Malatia / compiled at the Intelligence Division, War Office by Major F.R. Maunsell, R.A.., W.J. Anderson",
          language: :eng
        )
      ]
      expect(output.source_metadata_identifier).to eq ["6866386"]
    end
  end
end
