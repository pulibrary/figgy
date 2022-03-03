# frozen_string_literal: true
require "rails_helper"

RSpec.describe DataSeeder do
  let(:seeder) { described_class.new(logger) }
  let(:many_files) { 2 }
  let(:mvw_volumes) { 2 }
  let(:sammel_files) { 2 }
  let(:sammel_vols) { 2 }
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }

  # stub out the log messages
  let(:logger) { double }
  before { allow(logger).to receive(:info) }

  describe "if run in production" do
    it "raises RuntimeError" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      expect { described_class.new(logger) }.to raise_error(RuntimeError, /production/)
    end
  end

  # combine tests to reduce expensive object creation
  describe "#generate_dev_data" do
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "generates lots of objects" do
      n_files = mvw_volumes + # each volume member has a fileset
                sammel_vols + #  each volume member has a fileset
                sammel_files +
                many_files +
                15 # geo files created
      n_scanned_resources = mvw_volumes + sammel_vols +
                            1 + # the mvw parent
                            1 + # the many files parent
                            1 # the sammelband parent

      seeder.generate_dev_data(many_files: many_files, mvw_volumes: mvw_volumes, sammel_files: sammel_files, sammel_vols: sammel_vols)
      expect(query_service.find_all_of_model(model: FileSet).count).to eq n_files
      expect(query_service.find_all_of_model(model: ScannedResource).count).to eq n_scanned_resources
      expect(query_service.find_all_of_model(model: ScannedMap).count).to eq 12
      expect(query_service.find_all_of_model(model: RasterResource).count).to eq 2
      expect(query_service.find_all_of_model(model: VectorResource).count).to eq 1

      scanned_maps = query_service.find_all_of_model(model: ScannedMap)
      # held_by must be populated or the events can't be generated.
      expect(scanned_maps.flat_map(&:held_by).compact.length).to eq 12
      expect(scanned_maps.flat_map(&:held_by).uniq).to eq ["Princeton"]

      seeder.wipe_metadata!
      expect(Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_all.count).to eq 0

      seeder.wipe_files!
      expect(Dir.glob(Figgy.config["repository_path"]).count).to eq 1 # the dir itself
    end
  end

  describe "#generate_ephemera_project" do
    it "adds ephemera objects without boxes" do
      seeder.generate_ephemera_project(n_boxes: 0)
      expect(query_service.find_all_of_model(model: EphemeraProject).count).to eq 1
      expect(query_service.find_all_of_model(model: EphemeraBox).size).to eq 0
      expect(query_service.find_all_of_model(model: EphemeraFolder).size).to eq 3
    end

    it "adds ephemera objects with boxes" do
      seeder.generate_ephemera_project

      vocabs = query_service.find_all_of_model(model: EphemeraVocabulary).count
      expect(vocabs).to be > 1
      expect(query_service.find_all_of_model(model: EphemeraTerm).count).to be > vocabs
      expect(query_service.find_all_of_model(model: EphemeraProject).count).to eq 1
      d = query_service.find_all_of_model(model: EphemeraProject).first.decorate
      expect(d.members.count { |m| m.is_a? EphemeraField }).to eq 5
      expect(d.members.count { |m| m.is_a? EphemeraBox }).to eq 1
      d = query_service.find_all_of_model(model: EphemeraBox).first.decorate
      expect(d.members.count { |m| m.is_a? EphemeraFolder }).to eq 3
    end
  end

  describe "#generate_collection" do
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "adds a collection containing 3 scanned resources, 1 complete and 2 pending" do
      FactoryBot.create(:admin) # collection assigns an owner
      seeder.generate_collection

      expect(query_service.find_all_of_model(model: Collection).count).to eq 1
      resources = query_service.find_all_of_model(model: ScannedResource)
      expect(resources.count).to eq 3
      expect(resources.map(&:state)).to contain_exactly ["pending"], ["pending"], ["complete"]
    end
  end

  describe "#generate_archival_recording" do
    before do
      stub_aspace(pulfa_id: "C0652")
    end
    it "adds a recording with a file set containing 3 files" do
      seeder.generate_archival_recording
      recordings = query_service.find_all_of_model(model: ScannedResource)
      expect(recordings.count).to eq 1
      expect(recordings.first.change_set).to eq "recording"
      file_sets = Wayfinder.for(recordings.first).members
      expect(file_sets.count).to eq 1
      files = file_sets.first.file_metadata
      expect(files.map(&:original_filename)).to contain_exactly(
        ["32101047382492_1_a.mp3"], ["32101047382492_1_i.wav"], ["32101047382492_1_pm.wav"]
      )
    end
  end
end
