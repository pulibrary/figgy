# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSetDecorator do
  subject(:decorator) { described_class.new(file_set) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  it 'has no files which can be managed' do
    expect(decorator.manageable_files?).to be false
  end

  describe '#collections' do
    it "exposes parent collections" do
      expect(decorator.collections).to eq []
    end
  end

  describe '#parent' do
    it "exposes parent resources" do
      res = FactoryBot.create_for_repository(:scanned_resource)
      res.member_ids = [file_set.id]
      parent = adapter.persister.save(resource: res)

      expect(decorator.parent).to be_a parent.class
      expect(decorator.parent.id).to eq parent.id
    end
  end

  describe '#fixity_sort_date' do
    let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [file_metadata]) }

    describe 'when fixity_last_run_date exists' do
      let(:file_metadata) do
        FileMetadata.new(
          use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
          mime_type: 'image/tiff',
          fixity_last_run_date: Time.now.utc - 5.minutes
        )
      end

      it 'uses fixity_last_run_date' do
        allow(file_set).to receive(:created_at).and_call_original
        decorator.fixity_sort_date
        expect(file_set).not_to have_received(:created_at)
      end
    end

    describe 'when fixity_last_run_date is nil' do
      let(:file_metadata) do
        FileMetadata.new(
          use: [Valkyrie::Vocab::PCDMUse.OriginalFile],
          mime_type: 'image/tiff'
        )
      end

      it 'uses created_at' do
        allow(file_set).to receive(:created_at).and_call_original
        decorator.fixity_sort_date
        # you have to call it on the model or you get a string
        expect(file_set).to have_received(:created_at)
      end
    end
  end
end
