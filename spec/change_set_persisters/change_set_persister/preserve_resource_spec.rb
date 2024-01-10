# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::PreserveResource do
  with_queue_adapter :inline
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  context "when a file set is uploaded to a complete resource" do
    it "keeps metadata preserved" do
      stub_ezid

      resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
      file_set = Wayfinder.for(resource).file_sets.first
      file_set_preservation_object = Wayfinder.for(file_set).preservation_object

      expect(file_set_preservation_object.metadata_version).to eq file_set.optimistic_lock_token.first.token
    end
  end
end
