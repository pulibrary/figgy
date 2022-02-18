# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a Resource" do
  before do
    raise "resource must be set with `let(:resource)`" unless
      defined? resource
  end

  it_behaves_like "a Valkyrie::Resource"

  it "has a viewing_hint" do
    expect(described_class.fields).to include :viewing_hint
  end
  it "has a viewing direction" do
    expect(described_class.fields).to include :viewing_direction
  end

  it "has ordered member_ids" do
    resource = described_class.new
    resource.member_ids = [1, 2, 3, 3]
    expect(resource.member_ids).to eq [1, 2, 3, 3]
  end

  describe ".can_have_manifests?" do
    it "exposes IIIF Manifests" do
      expect(described_class.can_have_manifests?).to be true
    end
  end

  describe "#pdf_file" do
    let(:file_metadata) { FileMetadata.new mime_type: ["application/pdf"], use: [Valkyrie::Vocab::PCDMUse.OriginalFile] }

    it "retrieves only PDF FileSets" do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      resource = adapter.persister.save(resource: described_class.new(file_metadata: [file_metadata]))

      expect(resource.pdf_file).not_to be nil
      expect(resource.pdf_file).to be_a FileMetadata
    end
  end

  describe "#to_s" do
    it "returns the title if possible" do
      resource = described_class.new(title: ["One", "Two"])

      expect(resource.to_s).to eq "#{resource.human_readable_type}: One and Two"
    end
  end
end
