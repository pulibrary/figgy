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
      # number of objects to expect
      x = many_members * 2 + # each has a file set
          3 + # 1 for each generate_* method called (the resource)
          2 + # 1 for each generate_* method that creates a fileset
          many_files

      seeder.generate_dev_data(many_files: many_files, many_members: many_members)
      expect(Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_all.count).to eq x

      seeder.wipe_metadata!
      expect(Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_all.count).to eq 0

      seeder.wipe_files!
      expect(Dir.glob(Figgy.config['repository_path']).count).to eq 1 # the dir itself
    end
  end
end
