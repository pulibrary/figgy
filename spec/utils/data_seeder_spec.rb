# frozen_string_literal: true
require 'rails_helper'

RSpec.describe DataSeeder do
  let(:seeder) { described_class.new(logger) }
  let(:many_files) { 2 }
  let(:many_members) { 2 }

  # stub out the log messages
  let(:logger) { double }
  before { allow(logger).to receive(:info) }

  describe "if run in production" do
    it "raises RuntimeError" do
      allow(Rails).to receive(:env).and_return('production')
      expect { described_class.new(logger) }.to raise_error(RuntimeError, /production/)
    end
  end

  # combine tests to reduce expensive object creation
  describe "#generate_dev_data and #object_count_report" do
    it "generates lots of objects" do
      n_files = many_members + 1 + # parent, and each member has a fileset
                many_files +
                1 # the scanned map created
      n_scanned_resources = many_members + 1 + # the parent member
                            1 # the many files parent

      seeder.generate_dev_data(many_files: many_files, many_members: many_members)
      query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      expect(query_service.find_all_of_model(model: FileSet).count).to eq n_files
      expect(query_service.find_all_of_model(model: ScannedResource).count).to eq n_scanned_resources
      expect(query_service.find_all_of_model(model: ScannedMap).count).to eq 1
      vocabs = query_service.find_all_of_model(model: EphemeraVocabulary).count
      expect(vocabs).to be > 1
      expect(query_service.find_all_of_model(model: EphemeraTerm).count).to be > vocabs
      expect(query_service.find_all_of_model(model: EphemeraProject).count).to eq 1

      seeder.wipe_metadata!
      expect(Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_all.count).to eq 0

      seeder.wipe_files!
      expect(Dir.glob(Figgy.config['repository_path']).count).to eq 1 # the dir itself
    end
  end
end
