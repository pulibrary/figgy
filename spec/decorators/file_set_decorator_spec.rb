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

  describe "cloud fixity" do
    let(:good_file) { FileMetadata.new(label: "good.jp2", id: SecureRandom.uuid) }
    let(:bad_file) { FileMetadata.new(label: "bad.tif", id: SecureRandom.uuid) }
    let(:good_file_pres) { FileMetadata.new(preservation_copy_of_id: good_file.id, id: SecureRandom.uuid) }
    let(:bad_file_pres) { FileMetadata.new(preservation_copy_of_id: bad_file.id, id: SecureRandom.uuid) }
    let(:good_event) { FactoryBot.create_for_repository(:cloud_fixity_event, child_id: good_file_pres.id, status: "SUCCESS", current: true) }
    let(:bad_event) { FactoryBot.create_for_repository(:cloud_fixity_event, child_id: bad_file_pres.id, status: "FAILURE", current: true) }
    let(:pres_obj) { FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id, binary_nodes: [good_file_pres, bad_file_pres]) }
    let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [good_file, bad_file]) }

    before do
      pres_obj
      good_event
      bad_event
    end

    it "differentiates between the good and bad files" do
      expect(decorator.cloud_fixity_success_of(good_file.id)).to eq("SUCCESS")
      expect(decorator.cloud_fixity_last_success_date_of(good_file.id)).to eq(good_event.created_at)

      expect(decorator.cloud_fixity_success_of(bad_file.id)).to eq("FAILURE")
      expect(decorator.cloud_fixity_last_success_date_of(bad_file.id)).to eq("n/a")
    end

    context "when there's no preservation for a file" do
      let(:good_file_pres) { FileMetadata.new(preservation_copy_of_id: SecureRandom.uuid, id: SecureRandom.uuid) }
      it "returns in progress" do
        expect(decorator.cloud_fixity_success_of(good_file.id)).to eq nil
        expect(decorator.cloud_fixity_last_success_date_of(good_file.id)).to eq("n/a")
      end
    end
  end

  describe "#bounds" do
    let(:bounds) { [{ north: 71.0, east: 80.0, south: 70.0, west: 81.0 }] }

    before do
      allow(file_set).to receive(:bounds).and_return(bounds)
    end

    it "returns a rendered bounds string" do
      expect(decorator.bounds).to include "North: 71.0"
    end
  end
end
