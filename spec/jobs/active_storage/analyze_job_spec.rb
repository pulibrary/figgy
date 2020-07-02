# frozen_string_literal: true
require "rails_helper"

RSpec.describe ActiveStorage::AnalyzeJob do
  describe "#perform" do
    after do
      clear_enqueued_jobs
    end

    context "with a resource that has no blob" do
      include ActiveJob::TestHelper
      it "rescues and does not re-raise the ActiveJob::DeserializationError" do
        expect do
          perform_enqueued_jobs do
            fixture_path = Rails.root.join("spec", "fixtures", "files", "sample.pdf")
            resource = FactoryBot.create(:ocr_request, file: fixture_path)
            blob = resource.pdf.blob
            resource.pdf.purge
            described_class.perform_later(blob)
          end
        end.not_to raise_error
      end
    end
  end
end
