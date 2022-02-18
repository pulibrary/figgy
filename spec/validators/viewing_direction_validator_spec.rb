# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewingDirectionValidator do
  subject(:validator) { described_class.new }

  describe "#validate" do
    let(:errors) { double("Errors") }
    before do
      allow(errors).to receive(:add)
    end
    ["left-to-right", "right-to-left", "top-to-bottom", "bottom-to-top"].each do |direction|
      context "when viewing_direction is #{direction}" do
        it "does not add errors" do
          record = build_record(viewing_direction: direction)

          validator.validate(record)

          expect(errors).not_to have_received(:add)
        end
      end
    end

    context "when viewing direction is blank" do
      it "does not add errors" do
        record = build_record(viewing_direction: nil)

        validator.validate(record)

        expect(errors).not_to have_received(:add)
      end
    end

    context "when viewing direction is not acceptable" do
      it "adds errors" do
        record = build_record(viewing_direction: ["bad"])

        validator.validate(record)

        expect(errors).to have_received(:add).with(:viewing_direction, :inclusion, allow_blank: true, value: ["bad"])
      end
    end
  end

  def build_record(viewing_direction:)
    record = instance_double ScannedResourceChangeSet
    allow(record).to receive(:errors).and_return(errors)
    allow(record).to receive(:viewing_direction).and_return(viewing_direction)
    allow(record).to receive(:read_attribute_for_validation).with(:viewing_direction).and_return(record.viewing_direction)
    record
  end
end
