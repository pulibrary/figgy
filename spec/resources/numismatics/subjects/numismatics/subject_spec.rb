# frozen_string_literal: true

require "rails_helper"

describe Numismatics::Subject do
  subject(:numismatic_subject) { described_class.new type: "Animal", subject: "unicorn" }

  it "has properties" do
    expect(numismatic_subject.type).to eq(["Animal"])
    expect(numismatic_subject.subject).to eq(["unicorn"])
  end
end
