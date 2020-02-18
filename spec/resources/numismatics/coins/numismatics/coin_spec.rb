# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::Coin do
  let(:coin) { FactoryBot.create_for_repository(:coin, weight: 5, identifier: "ark:/99999/fk4") }

  it "has properties" do
    expect(coin.weight).to eq([5])
  end

  it "has ordered member_ids" do
    coin.member_ids = [1, 2, 3, 3]
    expect(coin.member_ids).to eq [1, 2, 3, 3]
  end

  it "has a title" do
    expect(coin.title).to include "Coin: 1"
  end

  it "has an identifier" do
    expect(coin.identifier).to eq ["ark:/99999/fk4"]
  end

  describe "#pdf_file" do
    let(:file_metadata) { FileMetadata.new mime_type: ["application/pdf"], use: [Valkyrie::Vocab::PCDMUse.OriginalFile] }
    it "retrieves only PDF FileSets" do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      resource = adapter.persister.save(resource: described_class.new(file_metadata: [file_metadata], state: "complete"))

      expect(resource.pdf_file).not_to be nil
      expect(resource.pdf_file).to be_a FileMetadata
    end
  end
end
