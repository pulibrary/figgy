# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::PreservationFileMigrator do
  describe ".call" do
    it "migrates the old values" do
      new_use_fileset = FactoryBot.create_for_repository(:audio_file_set)
      old_use_fm = FileMetadata.new(mime_type: "audio/x-wav", use: Valkyrie::Vocab::PCDMUse.PreservationMasterFile, id: "original")
      old_use_fileset = FactoryBot.create_for_repository(:file_set, file_metadata: [old_use_fm])

      described_class.call

      expect(query_service.find_by(id: old_use_fileset.id).primary_file.use).to eq [Valkyrie::Vocab::PCDMUse.PreservationFile]
      expect(query_service.find_by(id: new_use_fileset.id).updated_at).to eq new_use_fileset.updated_at # wasn't updated
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
  end
end
