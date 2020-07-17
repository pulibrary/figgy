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
    allow(CDL::EventLogging).to receive(:google_charge_event)
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

  describe "#activate_holds" do
    context "it has no available charge slots" do
      it "does nothing" do
        charged_items = [
          CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 3.hours)
        ]
        holds = [
          CDL::Hold.new(netid: "zelda")
        ]
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: holds)
        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        charge_manager.activate_holds!

        reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
        expect(reloaded_charges.updated_at).to eq resource_charge_list.updated_at
      end
    end
    context "it has an available charge slot, but a hold is already active" do
      it "does nothing" do
        charged_items = [
          CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current - 3.hours)
        ]
        holds = [
          CDL::Hold.new(netid: "zelda", expiration_time: 1.hour.from_now),
          CDL::Hold.new(netid: "miku")
        ]
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: holds)
        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        charge_manager.activate_holds!

        reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
        expect(reloaded_charges.updated_at).to eq resource_charge_list.updated_at
      end
    end
    context "it has an available charge slot and an expired hold" do
      with_queue_adapter :inline
      it "removes the expired hold, activates the new hold, and notifies both users" do
        charged_items = [
          CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current - 3.hours)
        ]
        User.create!(uid: "skye", email: "skye@princeton.edu")
        User.create!(uid: "miku", email: "miku@princeton.edu")
        holds = [
          CDL::Hold.new(netid: "miku", expiration_time: 1.hour.ago),
          CDL::Hold.new(netid: "skye")
        ]
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: holds)
        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        charge_manager.activate_holds!

        reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
        expect(reloaded_charges.hold_queue.size).to eq 1
        expect(reloaded_charges.hold_queue.first).to be_active
        expect(ActionMailer::Base.deliveries.size).to eq 2

        expired_hold_mail = ActionMailer::Base.deliveries.first
        expect(expired_hold_mail.to).to eq ["miku@princeton.edu"]
        expect(expired_hold_mail.subject).to eq "Digital Checkout Reservation Expired: Title"
        activated_hold_mail = ActionMailer::Base.deliveries.last
        expect(activated_hold_mail.subject).to eq "Available for Digital Checkout: Title"
      end
    end
    context "it has an available charge slot" do
      with_queue_adapter :inline
      it "activates the hold and notifies the user" do
        charged_items = [
          CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current - 3.hours)
        ]
        User.create!(uid: "skye", email: "skye@princeton.edu")
        holds = [
          CDL::Hold.new(netid: "miku", expiration_time: 1.hour.from_now),
          CDL::Hold.new(netid: "skye")
        ]
        eligible_item_service = EligibleItemService.new(item_ids: ["1234", "4567"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: holds)
        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        charge_manager.activate_holds!

        reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
        expect(reloaded_charges.hold_queue.first).to be_active
        expect(reloaded_charges.hold_queue.last).to be_active
        expect(ActionMailer::Base.deliveries.size).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.to).to eq ["skye@princeton.edu"]
        expect(mail.subject).to eq "Available for Digital Checkout: Title"
      end
    end
  end
  describe "#create_hold" do
    context "it is not available for charge" do
      context "there is a ResourceChargeList and an existing unexpired hold for that user" do
        it "raises CDL::HoldExists" do
          charged_items = [
            CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 3.hours)
          ]
          holds = [
            CDL::Hold.new(netid: "zelda")
          ]
          eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

          resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: holds)
          charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

          expect { charge_manager.create_hold(netid: "zelda") }.to raise_error CDL::HoldExists
          reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
          expect(reloaded_charges.hold_queue.length).to eq 1
        end
      end
      context "there is a ResourceChargeList and an existing expired hold for that user" do
        it "creates a new hold" do
          charged_items = [
            CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 3.hours)
          ]
          holds = [
            CDL::Hold.new(netid: "zelda", expiration_time: 1.hour.ago)
          ]
          eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

          resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items, hold_queue: holds)
          charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

          charge_manager.create_hold(netid: "zelda")
          reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
          expect(reloaded_charges.hold_queue.length).to eq 2
        end
      end
      context "there is a ResourceChargeList and no existing hold" do
        it "creates a hold" do
          charged_items = [
            CDL::ChargedItem.new(item_id: "1234", netid: "skye", expiration_time: Time.current + 3.hours)
          ]
          eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

          resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)
          charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

          charge_manager.create_hold(netid: "miku")
          reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
          expect(reloaded_charges.hold_queue).to be_present
          hold = reloaded_charges.hold_queue.first
          expect(hold.netid).to eq "miku"
        end
      end
    end
    context "it is available for charge" do
      it "creates a charge instead" do
        charged_items = []
        eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
        stub_bibdata(bib_id: "123456")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

        resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, charged_items: charged_items)
        charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

        charge_manager.create_hold(netid: "miku")
        reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
        expect(reloaded_charges.hold_queue).to be_empty
        expect(reloaded_charges.charged_items).not_to be_empty
      end
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
          expect(CDL::EventLogging).to have_received(:google_charge_event).with(netid: "skye", source_metadata_identifier: "123456")
        end
        it "removes any existing holds for that netid" do
          eligible_item_service = EligibleItemService.new(item_ids: ["1234"])
          stub_bibdata(bib_id: "123456")
          resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")

          resource_charge_list = FactoryBot.create_for_repository(:resource_charge_list, resource_id: resource.id, hold_queue: CDL::Hold.new(netid: "skye", expiration_time: Time.current + 1.hour))
          charge_manager = described_class.new(resource_id: resource.id, eligible_item_service: eligible_item_service, change_set_persister: change_set_persister)

          charged_item = charge_manager.create_charge(netid: "skye")
          expect(charged_item).to be_a CDL::ChargedItem
          reloaded_charges = Valkyrie.config.metadata_adapter.query_service.find_by(id: resource_charge_list.id)
          expect(reloaded_charges.charged_items).to be_present
          expect(reloaded_charges.hold_queue).to be_empty
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
end
