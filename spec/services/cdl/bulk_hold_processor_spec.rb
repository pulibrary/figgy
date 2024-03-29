# frozen_string_literal: true

require "rails_helper"

RSpec.describe CDL::BulkHoldProcessor do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  before do
    allow(CDL::EventLogging).to receive(:google_charge_event)
    allow(CDL::EventLogging).to receive(:google_hold_event)
    allow(CDL::EventLogging).to receive(:google_hold_charged_event)
    allow(CDL::EventLogging).to receive(:google_hold_expired_event)
  end
  it "expires all expired holds" do
    allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
    User.create!(uid: "one", email: "one@princeton.edu")
    User.create!(uid: "two", email: "two@princeton.edu")
    resource_charge_list1 = FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource).id,
      expired_hold_netids: ["one", "two"]
    )
    resource_charge_list2 = FactoryBot.create_for_repository(:resource_charge_list, resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource).id)

    described_class.process!

    reloaded_resource_charge_list1 = query_service.find_by(id: resource_charge_list1.id)
    expect(reloaded_resource_charge_list1.updated_at).not_to eq resource_charge_list1.updated_at
    expect(reloaded_resource_charge_list1.hold_queue).to be_empty
    expect(query_service.find_by(id: resource_charge_list2.id).updated_at).to eq resource_charge_list2.updated_at
  end

  it "activates any eligible holds" do
    allow(CDL::EligibleItemService).to receive(:item_ids).and_return(["1"])
    User.create!(uid: "one", email: "one@princeton.edu")
    User.create!(uid: "two", email: "two@princeton.edu")
    stub_catalog(bib_id: "991234563506421")
    stub_catalog(bib_id: "9946093213506421")
    resource_charge_list1 = FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "991234563506421").id,
      inactive_hold_netids: ["one", "two"]
    )
    resource_charge_list2 = FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "991234563506421").id
    )
    resource_charge_list3 = FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "991234563506421").id,
      inactive_hold_netids: ["one"]
    )

    described_class.process!

    reloaded_resource_charge_list1 = query_service.find_by(id: resource_charge_list1.id)
    expect(reloaded_resource_charge_list1.updated_at).not_to eq resource_charge_list1.updated_at
    expect(reloaded_resource_charge_list1.hold_queue.size).to eq 2
    expect(reloaded_resource_charge_list1.active_holds.size).to eq 1
    expect(reloaded_resource_charge_list1.active_holds[0].netid).to eq "one"

    expect(query_service.find_by(id: resource_charge_list2.id).updated_at).to eq resource_charge_list2.updated_at

    # Ensure all resources are activated.
    reloaded_resource_charge_list3 = query_service.find_by(id: resource_charge_list3.id)
    expect(reloaded_resource_charge_list3.hold_queue.size).to eq 1
    expect(reloaded_resource_charge_list3.active_holds.size).to eq 1
  end
end
