# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe PDFDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    PDFDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_change_set) { ChangeSet.for(valid_resource) }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    # TODO: do we need to ensure the file use is original?
    # Think about idempotence, re-generating failed derivatives or pages.

    context "when given a pdf mime_type" do
      it { is_expected.to be_valid }
    end

    context "when given a tiff mime_type" do
      it "is not valid" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/tiff"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.not_to be_valid
      end
    end
  end

  describe "#create_derivatives", run_real_derivatives: true, run_real_characterization: true do
    with_queue_adapter :inline
    it "creates an intermediate tiff for each page and marks the pdf as preservation master" do
      derivative_service.new(id: valid_change_set.id).create_derivatives

      reloaded_members = query_service.find_members(resource: scanned_resource)

      intermediate_files = reloaded_members.flat_map(&:file_metadata).select(&:intermediate_file?)
      expect(reloaded_members.reject { |fs| fs.preservation_file.nil? }.map(&:id).first).to eq valid_resource.id
      expect(intermediate_files.count).to eq 2
      expect(intermediate_files.first.checksum.first).not_to eq intermediate_files.last.checksum.first
    end
  end
end
