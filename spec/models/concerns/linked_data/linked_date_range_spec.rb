# frozen_string_literal: true

require "rails_helper"

RSpec.describe LinkedData::LinkedDateRange do
  subject(:linked_date_range) { described_class.new(resource: date_range).without_context }

  context "when the range has just start and end" do
    let(:date_range) { DateRange.new(start: "2013", end: "2017") }

    it "exposes the values as a nested date range" do
      expect(linked_date_range).to eq(
        "@type" => "edm:TimeSpan",
        "begin" => ["2013"],
        "end" => ["2017"]
      )
    end
  end

  context "when the range is approximate" do
    let(:date_range) { DateRange.new(start: "2013", end: "2017", approximate: true) }

    it "exposes additional properties" do
      expect(linked_date_range).to eq(
        "@type" => "edm:TimeSpan",
        "begin" => ["2013"],
        "end" => ["2017"],
        "crm:P79_beginning_is_qualified_by" => "approximate",
        "crm:P80_end_is_qualified_by" => "approximate",
        "skos:prefLabel" => "approximately 2013-2017"
      )
    end
  end
end
