# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe BagValidationJob do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }
  let(:media_resource) { FactoryBot.create_for_repository(:media_resource) }

  describe "#perform" do
    before do
      allow(Bagit::BagValidator).to receive(:validate).and_return(true)
    end

    it 'saves the resource with new bag fixity values' do
      resource = query_service.find_by(id: media_resource.id)
      expect(resource.bag_validation_success).to be nil

      described_class.perform_now(media_resource.id)
      resource = query_service.find_by(id: media_resource.id)
      expect(resource.bag_validation_success.first).to eq 1
      expect(resource.bag_validation_last_success_date.first).to be_a Time
    end
  end
end
