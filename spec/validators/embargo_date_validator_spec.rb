# frozen_string_literal: true
require "rails_helper"

RSpec.describe EmbargoDateValidator do
  subject(:validator) { described_class.new }

  describe "#validate" do
    let(:errors) { instance_double("Errors") }
    before do
      allow(errors).to receive(:add)
    end

    context "when embargo_date is nil" do
      it "does not add errors" do
        record = build_record(embargo_date: nil)
        validator.validate(record)
        expect(errors).not_to have_received(:add)
      end
    end

    context "when embargo_date is in the correct format" do
      it "does not add errors" do
        record = build_record(embargo_date: "8/3/2022")
        validator.validate(record)
        expect(errors).not_to have_received(:add)
      end
    end

    context "when embargo_date has leading zeros" do
      it "adds errors" do
        record = build_record(embargo_date: "08/03/2022")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:embargo_date, /Date must have form/)
      end
    end

    context "when embargo_date has incorrect month values" do
      it "adds errors" do
        record = build_record(embargo_date: "14/3/2022")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:embargo_date, /Date must have form/)
      end
    end

    context "when embargo_date has incorrect day values" do
      it "adds errors" do
        record = build_record(embargo_date: "4/40/2022")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:embargo_date, /Date must have form/)
      end
    end

    context "when embargo_date has incorrect year values" do
      it "adds errors" do
        record = build_record(embargo_date: "4/12/22")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:embargo_date, /Date must have form/)
      end
    end

    context "when embargo_date is not a date" do
      it "adds errors" do
        record = build_record(embargo_date: "not a date")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:embargo_date, /Date must have form/)
      end
    end
  end

  def build_record(embargo_date:)
    record = instance_double ScannedResourceChangeSet
    allow(record).to receive(:errors).and_return(errors)
    allow(record).to receive(:embargo_date).and_return(embargo_date)
    record
  end
end
