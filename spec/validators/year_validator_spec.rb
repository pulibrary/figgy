# frozen_string_literal: true

require "rails_helper"

RSpec.describe YearValidator do
  subject(:validator) { described_class.new(attributes: attributes) }

  describe "#validate" do
    let(:errors) { double("Errors") }
    let(:attributes) { [:start] }

    before do
      allow(errors).to receive(:add)
    end

    context "with a postive four digit year" do
      it "does not add errors" do
        record = build_record(start: "1979")

        validator.validate(record)

        expect(errors).not_to have_received(:add)
      end
    end

    context "with a negative one digit year" do
      it "does not add errors" do
        record = build_record(start: "-1")

        validator.validate(record)

        expect(errors).not_to have_received(:add)
      end
    end

    context "with a five digit year" do
      it "adds errors" do
        record = build_record(start: "12345")

        validator.validate(record)

        expect(errors).to have_received(:add).with(:start, "is not a valid year.")
      end
    end

    context "with a string that does not correspond to an integer" do
      it "adds errors" do
        record = build_record(start: "not an integer")

        validator.validate(record)

        expect(errors).to have_received(:add).with(:start, "is not a valid year.")
      end
    end
  end

  def build_record(start:)
    record = instance_double DateRangeChangeSet
    allow(record).to receive(:errors).and_return(errors)
    allow(record).to receive(:start).and_return(start)
    allow(record).to receive(:read_attribute_for_validation).with(:start).and_return(record.start)
    record
  end
end
