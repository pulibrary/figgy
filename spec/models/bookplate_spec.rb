# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Bookplate do
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"

  it "has a viewing_hint" do
    expect(described_class.schema.keys).to include :viewing_hint
  end
  it "has a viewing direction" do
    expect(described_class.schema.keys).to include :viewing_direction
  end

  it "has ordered member_ids" do
    bookplate = described_class.new
    bookplate.member_ids = [1, 2, 3, 3]
    expect(bookplate.member_ids).to eq [1, 2, 3, 3]
  end

  describe '.can_have_manifests?' do
    it 'exposes IIIF Manifests' do
      expect(described_class.can_have_manifests?).to be true
    end
  end

  describe '#to_s' do
    let(:bookplate) { FactoryBot.create :bookplate, title: 'Foo' }
    it 'generates a string for the instance' do
      expect(bookplate.to_s).to eq 'Bookplate: Foo'
    end
  end

  describe '#pdf_file' do
    let(:file_metadata) { FileMetadata.new mime_type: ["application/pdf"], use: [Valkyrie::Vocab::PCDMUse.OriginalFile] }

    it 'retrieves only PDF FileSets' do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      bookplate = adapter.persister.save(resource: described_class.new(file_metadata: [file_metadata]))

      expect(bookplate.pdf_file).not_to be nil
      expect(bookplate.pdf_file).to be_a FileMetadata
    end
  end
end
