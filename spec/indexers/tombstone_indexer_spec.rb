# frozen_string_literal: true
require "rails_helper"

RSpec.describe TombstoneIndexer do
  describe ".to_solr" do
    it "indexes the FileSet title" do
      tombstone = FactoryBot.create_for_repository(:tombstone, file_set_title: ["example.tif"])
      output = described_class.new(resource: tombstone).to_solr
      expect(output["title_tesim"]).to eq [tombstone.file_set_title]
      expect(output["title_ssim"]).to eq [tombstone.file_set_title]
      expect(output["title_tsim"]).to eq [tombstone.file_set_title]
    end
  end
end
