# frozen_string_literal: true
require "rails_helper"

describe GeneratePdfJob do
  describe "#perform" do
    it "wraps PDFService" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      pdf_service_double = instance_double(PDFService)
      allow(PDFService).to receive(:new).and_return(pdf_service_double)
      allow(pdf_service_double).to receive(:find_or_generate)

      described_class.perform_now(resource_id: resource.id)
      expect(pdf_service_double).to have_received(:find_or_generate)
    end
  end
end
