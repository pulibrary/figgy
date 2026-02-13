require "rails_helper"

RSpec.describe Migrations::IsPortionMigrator do
  describe ".call" do
    it "sets is_portion to true for resources with a portion_note" do
      query_service = ChangeSetPersister.default.query_service
      sr = FactoryBot.create_for_repository(:scanned_resource, portion_note: "Part 1")
      sm = FactoryBot.create_for_repository(:scanned_map, portion_note: "Sheet 2")

      described_class.call

      reloaded_sr = query_service.find_by(id: sr.id)
      reloaded_sm = query_service.find_by(id: sm.id)
      expect(reloaded_sr.is_portion).to be true
      expect(reloaded_sm.is_portion).to be true
    end

    it "does not modify resources without a portion_note" do
      query_service = ChangeSetPersister.default.query_service
      sr = FactoryBot.create_for_repository(:scanned_resource, title: "No portion note")

      described_class.call

      reloaded = query_service.find_by(id: sr.id)
      expect(reloaded.is_portion).to be_nil
    end
  end
end
