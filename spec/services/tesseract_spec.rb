# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tesseract do
  subject { described_class.new }

  describe "#languages" do
    before do
      allow(described_class).to receive(:language_output).and_return("List of available languages (107):\neng\nita\nbanana\nrfccode")
      allow(ISO_639).to receive(:find_by_code).and_call_original
      rfc_stub = instance_double(ISO_639, english_name: "Translated")
      allow(ISO_639).to receive(:find_by_code).with("rfccode").and_return(rfc_stub)
    end
    it "lists all available languages" do
      expect(described_class.languages).to eq(
        eng: "English",
        ita: "Italian",
        banana: "banana",
        rfccode: "Translated"
      )
    end
  end
end
