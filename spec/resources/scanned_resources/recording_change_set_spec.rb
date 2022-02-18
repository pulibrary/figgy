# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordingChangeSet do
  subject(:change_set) { described_class.new(resource) }

  describe "#preserve?" do
    context "when not a member of an archival media collection" do
      let(:resource) { FactoryBot.create_for_repository(:complete_recording) }

      it "is not preserved" do
        expect(change_set.preserve?).to be false
      end
    end

    context "when a member of an archival media collection" do
      let(:collection) { FactoryBot.create_for_repository(:archival_media_collection) }
      let(:resource) { FactoryBot.create_for_repository(:complete_recording, member_of_collection_ids: [collection.id]) }

      it "is preserved" do
        expect(change_set.preserve?).to be true
      end
    end
  end

  describe "#logical_structure" do
    let(:resource) { FactoryBot.create_for_repository(:complete_recording) }
    it "responds to it" do
      expect(change_set).to respond_to :logical_structure
    end
  end
end
