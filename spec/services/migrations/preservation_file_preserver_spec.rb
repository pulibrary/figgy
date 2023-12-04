# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::PreservationFilePreserver do
  describe ".call" do
    it "migrates the old values" do
      FactoryBot.create_for_repository(:audio_file_set)
      FactoryBot.create_for_repository(:pdf_file_set)

      expect do
        described_class.call
      end.to have_enqueued_job(PreserveResourceJob).exactly(:twice)
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
  end
end
