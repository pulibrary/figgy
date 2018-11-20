# frozen_string_literal: true
require "rails_helper"

describe NumismaticAccession do
  subject(:accession) { described_class.new date: "9/10/2011", type: "purchase", items_number: 102, number_in_accession: 2 }

  it "has properties" do
    expect(accession.date).to eq(["9/10/2011"])
    expect(accession.type).to eq(["purchase"])
    expect(accession.items_number).to eq(102)
    expect(accession.number_in_accession).to eq(2)
  end

  it "has a title" do
    expect(accession.title).to include "Accession: "
  end
end
