# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSetDecorator do
  subject(:decorator) { described_class.new(file_set) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  it "has no files which can be managed" do
    expect(decorator.manageable_files?).to be false
  end

  it "has no files to be ordered" do
    expect(decorator.orderable_files?).to be false
  end

  describe "#collections" do
    it "exposes parent collections" do
      expect(decorator.collections).to eq []
    end
  end

  describe "#parent" do
    it "exposes parent resources" do
      res = FactoryBot.create_for_repository(:scanned_resource)
      res.member_ids = [file_set.id]
      parent = adapter.persister.save(resource: res)

      expect(decorator.parent).to be_a parent.class
      expect(decorator.parent.id).to eq parent.id
    end
    context "when a parent resource cannot be resolved" do
      it "provides nil" do
        expect(decorator.parent).to be nil
      end
    end
  end

  describe "#downloadable?" do
    before do
      res = FactoryBot.create_for_repository(:scanned_resource)
      res.member_ids = [file_set.id]
      adapter.persister.save(resource: res)
    end

    it "delegates to the parent resource" do
      expect(decorator.downloadable?).to be true
    end
  end

  describe "#cloud_fixity_status" do
    let(:event) { FactoryBot.build :event, status: event_status }
    let(:preservation_obj) { instance_double("PreservationObject") }
    before do
      allow(decorator.wayfinder).to receive(:preservation_objects).and_return([preservation_obj])
      allow(preservation_obj).to receive_message_chain(:decorate, :events).and_return([event])
    end

    context "failure" do
      let(:event_status) { "FAILURE" }

      it "converts to failed" do
        expect(decorator.cloud_fixity_status).to eq("failed")
      end
    end

    context "success" do
      let(:event_status) { "SUCCESS" }

      it "converts to failed" do
        expect(decorator.cloud_fixity_status).to eq("succeeded")
      end
    end
  end
end
