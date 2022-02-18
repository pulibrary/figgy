# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecharacterizeJob do
  describe ".perform" do
    let(:char) { instance_double("Valkyrie::Derivatives::FileCharacterizationService") }
    let(:child_file_set) { FactoryBot.create_for_repository(:file_set) }
    let(:parent_file_set) { FactoryBot.create_for_repository(:file_set) }
    let(:parent) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [parent_file_set.id, child.id]) }
    let(:child) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [child_file_set.id]) }

    before do
      allow(Valkyrie::Derivatives::FileCharacterizationService).to receive(:for).and_return(char)
      allow(char).to receive(:characterize)
      parent
    end

    it "invokes Valkyrie::Derivatives::FileCharacterizationService" do
      described_class.perform_now(parent.id)
      expect(char).to have_received(:characterize).twice
    end
  end
end
