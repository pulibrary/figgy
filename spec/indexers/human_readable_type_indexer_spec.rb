# frozen_string_literal: true
require 'rails_helper'

RSpec.describe HumanReadableTypeIndexer do
  describe ".to_solr" do
    let(:scanned_resource) { FactoryBot.create(:pending_scanned_resource) }
    it "indexes the human readable type name for a scanned resource" do
      output = described_class.new(resource: scanned_resource).to_solr

      expect(output[:human_readable_type_ssim]).to eq 'Scanned Resource'
    end

    context 'when a scanned resource has multiple volumes' do
      let(:child_volume) { FactoryBot.create_for_repository(:scanned_resource) }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [child_volume.id]) }
      it 'indexes the scanned resource as a multi-volume work' do
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:human_readable_type_ssim]).to eq 'Multi Volume Work'
      end
    end
  end
end
