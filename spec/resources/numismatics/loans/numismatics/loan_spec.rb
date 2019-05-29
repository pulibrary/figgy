# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Loan do
  subject(:loan) { described_class.new date_in: "2010-01-01 00:00:00", date_out: "2011-11-11 00:00:00", exhibit_name: "exhibit", note: "note", type: "type" }

  it "has properties" do
    expect(loan.date_in).to eq(["2010-01-01 00:00:00"])
    expect(loan.date_out).to eq(["2011-11-11 00:00:00"])
    expect(loan.exhibit_name).to eq(["exhibit"])
    expect(loan.note).to eq(["note"])
    expect(loan.type).to eq(["type"])
  end
end
