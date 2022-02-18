# frozen_string_literal: true

require "rails_helper"

RSpec.describe EphemeraBoxIndexer do
  describe ".to_solr" do
    it "indexes the title when it's a box" do
      box = FactoryBot.create_for_repository(:ephemera_box)
      output = described_class.new(resource: box).to_solr
      expect(output["title_tesim"]).to eq [box.decorate.title]
      expect(output["title_ssim"]).to eq [box.decorate.title]
      expect(output["title_tsim"]).to eq [box.decorate.title]
    end
  end
end
