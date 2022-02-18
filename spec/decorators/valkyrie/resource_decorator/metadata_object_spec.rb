# frozen_string_literal: true

require "rails_helper"

RSpec.describe Valkyrie::ResourceDecorator::MetadataObject do
  subject(:metadata_object) { described_class.new("test attribute", ["test value"]) }

  describe "#pdf_type_label" do
    subject(:metadata_object) { described_class.new("pdf_type", ["test value"]) }

    it "returns the overridden label for the pdf_type attribute" do
      expect(metadata_object.label).to eq "PDF Type"
    end
  end

  describe "#label" do
    it "returns the label for the attribute" do
      expect(metadata_object.label).to eq "Test Attribute"
    end
  end

  describe "#value" do
    it "returns the value for the attribute" do
      expect(metadata_object.value).to eq ["test value"]
    end
  end

  describe "#to_h" do
    it "returns a hash for the label and value for the attribute" do
      expect(metadata_object.to_h).to eq "label" => "Test Attribute", "value" => ["test value"]
    end
  end

  describe "#created_value" do
    context "with a year-only range" do
      subject(:metadata_object) { described_class.new("created", ["1970-01-01T00:00:00Z/1971-12-31T23:59:59Z"]) }

      it "returns the year for the value" do
        expect(metadata_object.value).to eq ["1970-1971"]
      end
    end

    context "with range" do
      subject(:metadata_object) { described_class.new("created", ["1970-01-02T00:00:00Z/1971-02-03T00:00:00Z"]) }

      it "returns the formatted range for the dates" do
        expect(metadata_object.value).to eq ["01/02/1970-02/03/1971"]
      end
    end

    context "with a single date" do
      subject(:metadata_object) { described_class.new("created", ["1970-03-04T00:00:00Z"]) }

      it "returns the formatted range for the dates" do
        expect(metadata_object.value).to eq ["03/04/1970"]
      end
    end

    context "with a conventional US-formatted date" do
      subject(:metadata_object) { described_class.new("created", ["01/01/1970"]) }

      it "returns the initial value" do
        expect(metadata_object.value).to eq ["01/01/1970"]
      end
    end

    context "with an invalid date" do
      subject(:metadata_object) { described_class.new("created", ["1970-13-05T00:00:00Z"]) }

      it "returns the initial value" do
        expect(metadata_object.value).to eq ["1970-13-05T00:00:00Z"]
      end
    end
  end

  describe "#identifier_value" do
    context "with a URL" do
      subject(:metadata_object) { described_class.new("identifier", ["https://example.com/resource"]) }

      it "generates a formatted link" do
        expect(metadata_object.value).to eq ["<a href='https://example.com/resource' alt='Identifier'>https://example.com/resource</a>"]
      end
    end

    context "with a string" do
      subject(:metadata_object) { described_class.new("identifier", ["doi:10.3390/systems4040037"]) }

      it "generates a formatted link" do
        expect(metadata_object.value).to eq ["doi:10.3390/systems4040037"]
      end
    end
  end
end
