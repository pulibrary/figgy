# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::Numismatics::MonogramType do
  subject(:type) { make_graphql_object(described_class, numismatic_issue, { ability: ability }) }
  let(:numismatic_issue) do
    FactoryBot.create_for_repository(:numismatic_monogram)
  end
  let(:ability) { instance_double(Ability, can?: true) }

  describe "class methods" do
    subject { described_class }

    it { is_expected.to have_field(:label).of_type(String) }
  end

  describe "#label" do
    it "maps to a resource's title" do
      expect(type.label).to eq "Test Monogram"
    end
  end
end
