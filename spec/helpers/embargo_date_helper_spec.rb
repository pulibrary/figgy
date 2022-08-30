# frozen_string_literal: true
require "rails_helper"

RSpec.describe EmbargoDateHelper, type: :helper do
  describe "#default_embargo_date" do
    context "with a valid date value" do
      it "returns a default-date property" do
        expect(helper.default_embargo_date("8/30/2022")).to include ":default-date"
      end
    end

    context "with a nil date value" do
      it "returns nil" do
        expect(helper.default_embargo_date(nil)).to be_nil
      end
    end

    context "with an empty string date value" do
      it "returns nil" do
        expect(helper.default_embargo_date("")).to be_nil
      end
    end
  end
end
