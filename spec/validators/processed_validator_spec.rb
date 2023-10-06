# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProcessedValidator do
  subject(:validator) { described_class.new }

  describe "#validate" do
    let(:errors) { instance_double("Errors") }
    let(:resource) { FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: file_set.id) }
    let(:record) { ChangeSet.for(resource) }

    before do
      allow(errors).to receive(:add)
      allow(record).to receive(:errors).and_return(errors)
      allow(record).to receive(:old_state).and_return("pending")
      allow(record).to receive(:new_state).and_return("complete")
    end

    context "when a resource FileSet is not in-process or pending" do
      let(:file_set) { FactoryBot.create_for_repository(:original_file_file_set) }

      it "does not add errors" do
        validator.validate(record)
        expect(errors).not_to have_received(:add)
      end
    end

    context "when a resource FileSet is in-process" do
      let(:file_set) { FactoryBot.create_for_repository(:original_file_file_set, processing_status: "in process") }

      it "does add errors" do
        validator.validate(record)
        expect(errors).to have_received(:add).with(:state, "Can't complete record while still in process")
      end
    end

    context "when a resource has pending uploads" do
      let(:file_set) { FactoryBot.create_for_repository(:original_file_file_set) }
      let(:pending_upload) { PendingUpload.new(id: SecureRandom.uuid, storage_adapter_id: "id") }
      let(:resource) { FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: file_set.id, pending_uploads: [pending_upload]) }

      it "does add errors" do
        validator.validate(record)
        expect(errors).to have_received(:add).with(:state, "Can't complete record while still in process")
      end
    end

    context "when a resource FileSet is in process, but the new state is not complete" do
      let(:file_set) { FactoryBot.create_for_repository(:original_file_file_set, processing_status: "in process") }

      before do
        allow(record).to receive(:new_state).and_return("metadata_review")
      end

      it "does not add errors" do
        validator.validate(record)
        expect(errors).not_to have_received(:add)
      end
    end
  end
end
