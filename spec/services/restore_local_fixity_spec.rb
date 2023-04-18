# frozen_string_literal: true
require "rails_helper"

RSpec.describe RestoreLocalFixity do
  with_queue_adapter :inline

  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ChangeSet.for(FactoryBot.create(:complete_scanned_resource), files: [file]))
  end
  let(:file_set) { scanned_resource.decorate.file_sets.first }

  before do
    allow(LocalFixityJob).to receive(:perform_later)
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
    scanned_resource
  end

  context "with an original file" do
    context "saved local checksum matches cloud file checksum" do
      it "replaces the local file with the file that has the correct checksum" do
        characterized_file_set = query_service.find_by(id: file_set.id)
        saved_local_checksum = characterized_file_set.original_file.checksum

        file_identifier = file_set.original_file.file_identifiers.first
        modify_file(file_identifier)

        described_class.run(characterized_file_set)
        expect(new_checksum(file_identifier)).to eq saved_local_checksum.first

        # This runs once at the end of derivative creation and once in the class under test
        expect(LocalFixityJob).to have_received(:perform_later).exactly(2).times
      end
    end

    context "saved local checksum does not match cloud file checksum" do
      it "doesn't replace the file" do
        characterized_file_set = query_service.find_by(id: file_set.id)
        saved_local_checksum = characterized_file_set.original_file.checksum

        file_identifier = file_set.original_file.file_identifiers.first
        modify_file(file_identifier)

        digest_double = double(hexdigest: "123")
        allow(Digest::MD5).to receive(:file).and_return(digest_double)

        described_class.run(characterized_file_set)
        expect(new_checksum(file_identifier)).not_to eq saved_local_checksum.first

        # This runs once at the end of derivative creation and once in the class under test
        expect(LocalFixityJob).to have_received(:perform_later).exactly(2).times
      end
    end
  end

  context "with an intermediate file and a preservation file" do
    let(:file) { fixture_file_with_use("files/example.tif", "image/tiff", Valkyrie::Vocab::PCDMUse.PreservationFile) }
    let(:intermediate_file) { fixture_file_with_use("files/example.tif", "image/tiff", Valkyrie::Vocab::PCDMUse.IntermediateFile) }

    context "local checksum matches cloud file checksum" do
      it "replaces the local files with files that have the correct checksum" do
        # Ingest intermediate file onto the FileSet
        change_set = ChangeSet.for(file_set)
        change_set.validate(files: [intermediate_file])
        change_set_persister.save(change_set: change_set)
        RecharacterizeJob.perform_now(file_set.id.to_s)

        characterized_file_set = query_service.find_by(id: file_set.id)

        preservation_checksum = characterized_file_set.preservation_file.checksum
        intermediate_checksum = characterized_file_set.intermediate_file.checksum

        preservation_identifier = characterized_file_set.preservation_file.file_identifiers.first
        intermediate_identifier = characterized_file_set.intermediate_file.file_identifiers.first
        modify_file(preservation_identifier)
        modify_file(intermediate_identifier)

        described_class.run(characterized_file_set)

        expect(new_checksum(preservation_identifier)).to eq preservation_checksum.first
        expect(new_checksum(intermediate_identifier)).to eq intermediate_checksum.first

        # This runs once at the end of derivative creation and once in the class under test
        expect(LocalFixityJob).to have_received(:perform_later).exactly(2).times
      end
    end

    context "local checksum does not match cloud file checksum for one file" do
      it "only replaces one file" do
        # Ingest intermediate file onto the FileSet
        change_set = ChangeSet.for(file_set)
        change_set.validate(files: [intermediate_file])
        change_set_persister.save(change_set: change_set)
        RecharacterizeJob.perform_now(file_set.id.to_s)

        characterized_file_set = query_service.find_by(id: file_set.id)

        preservation_checksum = characterized_file_set.preservation_file.checksum
        intermediate_checksum = characterized_file_set.intermediate_file.checksum

        preservation_identifier = characterized_file_set.preservation_file.file_identifiers.first
        intermediate_identifier = characterized_file_set.intermediate_file.file_identifiers.first
        modify_file(preservation_identifier)
        modify_file(intermediate_identifier)

        digest_double_bad = double(hexdigest: "123")
        digest_double_good = double(hexdigest: intermediate_checksum.first.md5)
        allow(Digest::MD5).to receive(:file).and_return(digest_double_bad, digest_double_good)

        described_class.run(characterized_file_set)

        expect(new_checksum(preservation_identifier)).not_to eq preservation_checksum.first
        expect(new_checksum(intermediate_identifier)).to eq intermediate_checksum.first

        # This runs once at the end of derivative creation and once in the class under test
        expect(LocalFixityJob).to have_received(:perform_later).exactly(2).times
      end
    end
  end

  # change the file on disk so it has a different checksum
  def modify_file(file_identifier)
    path = file_identifier.id.gsub("disk://", "")
    File.open(path, "w") do |f|
      f.write "p0wned"
    end
  end

  def new_checksum(file_identifier)
    file_object = Valkyrie::StorageAdapter.find_by(id: file_identifier)
    MultiChecksum.for(file_object)
  end
end
