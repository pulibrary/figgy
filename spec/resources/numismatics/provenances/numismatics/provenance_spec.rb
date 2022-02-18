# frozen_string_literal: true

require "rails_helper"

describe Numismatics::Provenance do
  subject(:provenance) { described_class.new date: "12/04/1999", note: "note" }

  it "has properties" do
    expect(provenance.date).to eq(["12/04/1999"])
    expect(provenance.note).to eq(["note"])
  end
end
