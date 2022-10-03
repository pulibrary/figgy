# frozen_string_literal: true

require "rails_helper"

RSpec.describe RunOCRJob do
  context "when the file no longer exists" do
    it "fails silently" do
      allow(HocrDerivativeService::Factory).to receive(:new).and_raise(Valkyrie::StorageAdapter::FileNotFound)
      expect { described_class.perform_now("bla") }.not_to raise_error
    end
  end

  context "when given a file set that doesn't exist" do
    it "doesn't raise an error" do
      expect { described_class.perform_now("bla") }.not_to raise_error
    end
  end
end
