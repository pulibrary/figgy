# frozen_string_literal: true

require "rails_helper"

RSpec.describe GeoResourceReindexer do
  let(:geo_work) do
    FactoryBot.build(:vector_resource,
      title: "Geo Work",
      coverage: coverage.to_s,
      visibility: "open",
      state: "complete",
      identifier: "ark:/99999/fk4")
  end
  let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032) }
  let(:change_set) { VectorResourceChangeSet.new(geo_work) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }

  before do
    change_set_persister.save(change_set: change_set)
  end

  describe "#reindex_geoblacklight" do
    let(:messenger) { instance_double(EventGenerator) }

    before do
      allow(EventGenerator).to receive(:new).and_return(messenger)
      allow(messenger).to receive(:record_updated)
    end

    context "with a valid geo resource" do
      it "sends an updated record message" do
        described_class.reindex_geoblacklight(logger: logger)
        expect(messenger).to have_received(:record_updated)
      end
    end

    context "with a geo resource that throws an exception" do
      let(:resource) { instance_double(VectorResource, state: "complete") }

      before do
        allow(EventGenerator).to receive(:new).and_raise("error")
      end

      it "does not send an updated record message" do
        described_class.reindex_geoblacklight(logger: logger)
        expect(messenger).not_to have_received(:record_updated)
      end
    end
  end

  describe "#reindex_geoserver" do
    let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
    let(:change_set) { VectorResourceChangeSet.new(geo_work, files: [file]) }
    let(:messenger) { instance_double(EventGenerator) }

    before do
      allow(EventGenerator).to receive(:new).and_return(messenger)
      allow(messenger).to receive(:derivatives_created)
    end

    context "with a valid geo resource and geo member" do
      it "sends a derivatives created message" do
        described_class.reindex_geoserver(logger: logger)
        expect(messenger).to have_received(:derivatives_created)
      end
    end

    context "with a geo resource that throws an exception" do
      before do
        allow(EventGenerator).to receive(:new).and_raise("error")
      end

      it "does not send a derivatives created message" do
        described_class.reindex_geoserver(logger: logger)
        expect(messenger).not_to have_received(:derivatives_created)
      end
    end
  end

  describe "#reindex_ogm" do
    let(:ogm_repo_path) { "./tmp/edu.princeton.arks" }

    context "with a valid geo resource" do
      after do
        FileUtils.rm_r(ogm_repo_path)
      end

      it "creates an OpenGeoMetadata repository and a layers.json file" do
        described_class.reindex_ogm(logger: logger, ogm_repo_path: ogm_repo_path)
        layers = JSON.parse(File.read("#{ogm_repo_path}/layers.json"))
        expect(File).to exist("#{ogm_repo_path}/fk/4/geoblacklight.json")
        expect(layers["ark:/99999/fk4"]).to eq("fk/4")
      end
    end

    context "when a geo resource has an invalid geoblacklight document" do
      let(:geo_work) { FactoryBot.build(:vector_resource) }

      it "does not save a geoblacklight document in the ogm repository" do
        described_class.reindex_ogm(logger: logger, ogm_repo_path: ogm_repo_path)
        expect(File).not_to exist("#{ogm_repo_path}/fk/4/geoblacklight.json")
      end
    end

    context "with a geo resource that throws an exception" do
      before do
        allow(GeoDiscovery::DocumentBuilder).to receive(:new).and_raise("error")
      end

      it "logs the exception and does not save a geoblacklight document in the ogm repository" do
        described_class.reindex_ogm(logger: logger, ogm_repo_path: ogm_repo_path)
        expect(File).not_to exist("#{ogm_repo_path}/fk/4/geoblacklight.json")
        expect(logger).to have_received(:warn)
      end
    end
  end
end
