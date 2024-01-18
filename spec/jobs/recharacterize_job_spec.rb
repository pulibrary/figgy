# frozen_string_literal: true
require "rails_helper"

RSpec.describe RecharacterizeJob do
  describe ".perform" do
    let(:change_set_persister) { ChangeSetPersister.default }
    let(:query_service) { change_set_persister.query_service }

    context "when passing a non-FileSet parent id" do
      it "invokes Valkyrie::Derivatives::FileCharacterizationService" do
        char = instance_double("Valkyrie::Derivatives::FileCharacterizationService")
        child_file_set = FactoryBot.create_for_repository(:file_set)
        parent_file_set = FactoryBot.create_for_repository(:file_set)
        child = FactoryBot.create_for_repository(:scanned_resource, member_ids: [child_file_set.id])
        parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: [parent_file_set.id, child.id])
        allow(Valkyrie::Derivatives::FileCharacterizationService).to receive(:for).and_return(char)
        allow(char).to receive(:characterize)
        described_class.perform_now(parent.id)
        expect(char).to have_received(:characterize).twice
      end
    end

    context "when provided with a file which is not a valid image file" do
      it "adds an error message to the file set" do
        file = fixture_file_upload("files/invalid.tif", "image/tiff")
        book = change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
        book_members = query_service.find_members(resource: book)
        invalid_file_set = book_members.first

        expect { described_class.perform_now(invalid_file_set.id) }.to raise_error(MiniMagick::Invalid)
        file_set = query_service.find_by(id: invalid_file_set.id)
        expect(file_set.file_metadata[0].error_message.first).to start_with "Error during characterization:"
      end
    end
  end
end
