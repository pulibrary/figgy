# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::BulkHoldProcessor do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  it "expires all expired holds" do
    allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
    User.create!(uid: "one", email: "one@princeton.edu")
    User.create!(uid: "two", email: "two@princeton.edu")
    hold1 = FactoryBot.create_for_repository(:resource_charge_list, resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource).id, expired_hold_netids: ["one", "two"])
    hold2 = FactoryBot.create_for_repository(:resource_charge_list, resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource).id)

    described_class.new(change_set_persister: ScannedResourcesController.change_set_persister).process!

    reloaded_hold1 = query_service.find_by(id: hold1.id)
    expect(reloaded_hold1.updated_at).not_to eq hold1.updated_at
    expect(query_service.find_by(id: hold2.id).updated_at).to eq hold2.updated_at
  end
end
