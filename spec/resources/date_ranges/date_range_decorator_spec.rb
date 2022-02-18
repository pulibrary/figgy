# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateRangeDecorator do
  subject(:decorator) { described_class.new(date_range) }

  describe "#range_string" do
    context "when the range has just start and end" do
      let(:date_range) { DateRange.new(start: "2000", end: "2009") }
      it "produces a simple range" do
        expect(decorator.range_string).to eq "2000-2009"
      end
    end

    context "when the range is approximate" do
      let(:date_range) { DateRange.new(start: "2000", end: "2009", approximate: true) }
      it "produces an approximate range" do
        expect(decorator.range_string).to eq "approximately 2000-2009"
      end
    end
  end
end
