# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunOCRJob do
  context "when the file no longer exists" do
    it "fails silently" do
      allow(HocrDerivativeService::Factory).to receive(:new).and_raise(Valkyrie::StorageAdapter::FileNotFound)
      expect { described_class.perform_now("bla") }.not_to raise_error
    end
  end

  context "when the parent doesn't have an hocr_language set" do
    let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    it "fails silently" do
      resource = FactoryBot.create_for_repository(:scanned_resource, files: [file])

      expect { described_class.perform_now(Wayfinder.for(resource).file_sets.first.id.to_s) }.not_to raise_error
    end
  end

  context "when given a file set that doesn't exist" do
    it "doesn't raise an error" do
      expect { described_class.perform_now("bla") }.not_to raise_error
    end
  end
end
