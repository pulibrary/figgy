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

  describe "#initialize" do
    it "clears expired charges from in-memory array" do
      stub_bibdata(bib_id: "123456")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")
      eligible_item_service = EligibleItemService.new(item_ids: ["1234"])

      Timecop.freeze(Time.current - 1.hour) do
        charged_items = [
          FactoryBot.build(:charged_item, expiration_time: Time.current + 1.hour)
        ]
        FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)

        manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(manager.resource_charge_list.charged_items.count).to eq 1
      end

      manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
      # It's been updated in memory, not on disk
      expect(manager.resource_charge_list.charged_items.count).to eq 0
      expect(Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: CDL::ResourceChargeList).first.charged_items.count).to eq 1
    end
  end

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
  end

  describe "#available_for_charge?" do
    context "when there are no items" do
      it "returns false" do
        eligible_item_service = EligibleItemService.new(item_ids: [])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        expect(charge_manager.eligible?).to eq false
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq false
      end
    end

    context "when there are items and nothing has ever been charged" do
      it "returns true" do
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq true
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
        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq true
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
        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq false
      end
    end
    context "when an item isn't charged but there's a hold queue" do
      it "returns false" do
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, hold_queue: CDL::Hold.new(netid: "tiberius"))

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq false
      end
    end
    context "when an item isn't charged and there's an active hold for that user" do
      it "returns true" do
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, hold_queue: CDL::Hold.new(netid: "miku", expiration_time: Time.current + 1.hour))

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq true
      end
    end
    # When and under what circumstances a hold is activated should be left to
    # the create_hold method. Don't worry about those logistics for checking
    # availability - if it's not an active hold, then don't let them charge.
    context "when an item isn't charged and there's an inactive hold for that user" do
      it "returns false" do
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, hold_queue: CDL::Hold.new(netid: "miku"))

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq false
      end
    end
    context "when an item isn't charged and there's an expired hold for that user" do
      it "returns false" do
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        FactoryBot.create_for_repository(
          :resource_charge_list,
          resource_id: resource.id,
          hold_queue: [
            CDL::Hold.new(netid: "miku", expiration_time: Time.current - 1.hour),
            CDL::Hold.new(netid: "tiberius")
          ]
        )

        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)
        expect(charge_manager.eligible?).to eq true
        expect(charge_manager.available_for_charge?(netid: "miku")).to eq false
      end
    end
  end

  describe "#estimated_wait_time" do
    it "uses the rails estimator" do
      charged_items = [
        CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 1.hour + 20.minutes),
        CDL::ChargedItem.new(item_id: "5678", netid: "zelda", expiration_time: Time.current + 3.hours)
      ]
      eligible_item_service = EligibleItemService.new(item_ids: ["1234", "5678"])
      stub_bibdata(bib_id: "123456")
      resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

      FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)

      charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

      expect(charge_manager.estimated_wait_time.to_s).to eq "about 1 hour"
    end
  end
end
