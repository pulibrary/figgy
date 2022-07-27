# frozen_string_literal: true
require "rails_helper"

RSpec.describe CleanDeletedSubjectJob do
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:query_service) { metadata_adapter.query_service }
  let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, subject: [subject_term.id, old_subject]) }
  let(:subject_term) { FactoryBot.create_for_repository(:ephemera_term, label: "Architecture") }
  let(:old_subject) { Valkyrie::ID.new("old_subject") }

  before do
    resource
  end

  describe ".perform" do
    it "deletes the bad subject from the subject array" do
      described_class.perform_now(old_subject.to_s)
      expect(query_service.find_by(id: resource.id).subject).to eq [subject_term.id]
    end

    context "when the changeset is invalid" do
      let(:change_set) { ChangeSet.for(resource) }
      let(:logger) { instance_double Logger }
      before do
        allow(ChangeSet).to receive(:for).and_call_original
        allow(ChangeSet).to receive(:for).with(resource).and_return(change_set)
        allow(change_set).to receive(:valid?).and_return(false)
        allow(logger).to receive(:warn)
      end
      it "logs an error" do
        described_class.perform_now(old_subject.to_s, logger: logger)
        expect(logger).to have_received(:warn).with "change set did not validate for #{resource.id}"
      end
    end
  end
end
