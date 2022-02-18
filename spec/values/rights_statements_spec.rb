# frozen_string_literal: true

require "rails_helper"

RSpec.describe RightsStatements do
  it "has rights statement constants" do
    [
      :copyright_not_evaluated,
      :in_copyright,
      :in_copyright_unknown_holders,
      :in_copyright_educational_use,
      :in_copyright_noncommercial_use,
      :no_copyright_contractual_restrictions,
      :no_copyright_other_restrictions,
      :no_known_copyright,
      :vatican_copyright
    ].each do |right|
      expect(described_class.__send__(right)).to be_a RDF::URI
    end
  end
end
