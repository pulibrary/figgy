# frozen_string_literal: true
require "rails_helper"

describe CDL::ChargeManager do
  before do
    class EligibleItemService
      attr_reader :cached_item_ids
      def initialize(item_ids:)
        @cached_item_ids = item_ids
      end

      def item_ids(source_metadata_identifier:)
        cached_item_ids
      end
    end
  end

  after do
    Object.send(:remove_const, :EligibleItemService)
  end

  let(:change_set_persister) { ScannedResourcesController.change_set_persister }

  describe "#create_charge" do
    context "it is available for charge" do
      context "there is a ResourceChargeList" do
        it "creates a charge" do
          eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

          resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id)
          charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

          charged_item = charge_manager.create_charge(netid: "skye")
          expect(charged_item).to be_a CDL::ChargedItem
          reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
          expect(reloaded_charges.charged_items).to be_present
        end
      end

      context "there is no ResourceChargeList" do
        it "creates a ResourceChargeList and places a Charge in it" do
          eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

          charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

          charged_item = charge_manager.create_charge(netid: "skye")
          expect(charged_item).to be_a CDL::ChargedItem
          reloaded_charges = Wayfinder.for(resource).resource_charge_list
          expect(reloaded_charges.charged_items).to be_present
        end
      end
    end

    context "it is not available for charge" do
      it "raises a CDL::UnavailableForCharge" do
        eligible_item_service = EligibleItemService.new(item_ids: [])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        expect { charge_manager.create_charge(netid: "zelda") }.to raise_error CDL::UnavailableForCharge
      end
    end
    # (netid:) (checks bibdata for items, compares with current charged items, if possible creates a charge.)
  end

  describe "#available_for_charge?" do
    context "when there are no items" do
      it "returns false" do
        eligible_item_service = EligibleItemService.new(item_ids: [])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        expect(charge_manager.available_for_charge?).to eq false
      end
    end

    context "when there are items and nothing has ever been charged" do
      it "returns true" do
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        expect(charge_manager.available_for_charge?).to eq true
      end
    end

    context "when one item is not currently charged" do
      it "returns true" do
        charged_items = [
          CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 3.hours)
        ]
        eligible_item_service = EligibleItemService.new(item_ids: ["1234", "5678"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(charge_manager.available_for_charge?).to eq true
      end
    end

    context "when all items are currently charged" do
      it "returns false" do
        charged_items = [
          CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 3.hours),
          CDL::ChargedItem.new(item_id: "5678", netid: "zelda", expiration_time: Time.current + 3.hours)
        ]
        eligible_item_service = EligibleItemService.new(item_ids: ["1234", "5678"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(charge_manager.available_for_charge?).to eq false
      end
    end
  end
end
