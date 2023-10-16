# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::PropagateOCRLanguage do
  context "when a parent has an ocr_language set" do
    it "propagates to existing children" do
      child = FactoryBot.create_for_repository(:scanned_resource)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: [child.id])

      change_set = ChangeSet.for(parent)
      change_set.validate(ocr_language: ["English"])
      parent = ChangeSetPersister.default.save(change_set: change_set)
      child = ChangeSetPersister.default.query_service.find_by(id: child.id)

      expect(parent.ocr_language).to eq ["English"]
      expect(child.ocr_language).to eq ["English"]
    end
    it "doesn't propagate if it isn't changed" do
      child = FactoryBot.create_for_repository(:scanned_resource, ocr_language: ["Spanish"])
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: [child.id])

      change_set = ChangeSet.for(parent)
      change_set.validate(title: ["Testing"])
      parent = ChangeSetPersister.default.save(change_set: change_set)
      child = ChangeSetPersister.default.query_service.find_by(id: child.id)

      expect(parent.ocr_language).to eq []
      expect(child.ocr_language).to eq ["Spanish"]
    end
    it "sets it for newly added resources" do
      parent = FactoryBot.create_for_repository(:scanned_resource, ocr_language: ["English"])

      child = FactoryBot.create_for_repository(:scanned_resource, append_id: parent.id)
      child = ChangeSetPersister.default.query_service.find_by(id: child.id)

      expect(child.ocr_language).to eq ["English"]
    end
  end
end
