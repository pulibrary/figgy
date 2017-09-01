# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ManifestBuilder::CantaloupeHelper do
  let(:cantaloupe_helper) { described_class.new }
  let(:file_set) { FactoryGirl.create_for_repository(:file_set) }
  let(:derivative_file) { instance_double(FileMetadata, nil?: false) }
  let(:query_service) { class_double(Valkyrie::Persistence::Postgres::QueryService) }

  describe '#base_url' do
    context 'with generated derivatives' do
      before do
        allow(derivative_file).to receive(:id).and_return('test')
        allow(file_set).to receive(:derivative_file).and_return(derivative_file)
        allow(query_service).to receive(:find_by).and_return(file_set)
        allow(Valkyrie.config.metadata_adapter).to receive(:query_service).and_return(query_service)
      end
      it 'generates a base URL for a JPEG2000 derivative' do
        expect(cantaloupe_helper.base_url(file_set.id)).to eq 'http://localhost:8182/iiif/2/test%2Fintermediate_file.jp2'
      end
    end
    context 'without generated derivatives' do
      it 'raises an Valkyrie::Persistence::ObjectNotFoundError' do
        expect { cantaloupe_helper.base_url(file_set.id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end
