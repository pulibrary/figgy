# frozen_string_literal: true
require "rails_helper"

RSpec.describe CharacterizationJob do
  describe ".perform" do
    let(:change_set_persister) { ChangeSetPersister.default }
    let(:query_service) { change_set_persister.query_service }

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
