# frozen_string_literal: true
require "rails_helper"

describe CDL::ResourceChargeList do
  describe "#resource_id" do
    it "returns the figgy id of the resource it manages charges for" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      charge_manager = described_class.new(resource_id: resource.id)
      expect(charge_manager.resource_id).to eq resource.id
    end
  end

  describe "#charged_items" do
    it "stores an array of ChargedItems" do
      charge_manager = described_class.new

      charged_item = CDL::ChargedItem.new(item_id: "1", netid: "skye", expiration_time: Time.zone.at(0))
      charge_manager.charged_items = [charged_item]

      expect(charge_manager.charged_items[0]).to eq charged_item
    end
  end

  it "has optimistic locking enabled" do
    resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list)
    change_set = ChangeSet.for(resource_charge_list)
    change_set.validate(resource_id: SecureRandom.uuid)
    ScannedResourcesController.change_set_persister.save(change_set: change_set)

    change_set = ChangeSet.for(resource_charge_list)
    change_set.validate(resource_id: SecureRandom.uuid)
    expect { ScannedResourcesController.change_set_persister.save(change_set: change_set) }.to raise_error Valkyrie::Persistence::StaleObjectError
  end
end
