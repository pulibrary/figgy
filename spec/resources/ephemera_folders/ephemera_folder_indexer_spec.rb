# frozen_string_literal: true

require "rails_helper"

RSpec.describe EphemeraFolderIndexer do
  describe ".to_solr" do
    context "when workflow is not yet complete" do
      it "indexes empty read group" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        output = described_class.new(resource: folder).to_solr
        expect(output["read_access_group_ssim"]).to be_empty
      end
    end

    context "when workflow is complete" do
      it "indexes read group public" do
        folder = FactoryBot.create_for_repository(:ephemera_folder, state: "complete")
        output = described_class.new(resource: folder).to_solr
        expect(output["read_access_group_ssim"]).to eq ["public"]
      end
    end
  end
end
