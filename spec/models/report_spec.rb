# frozen_string_literal: true
require "rails_helper"

RSpec.describe Report do
  let(:admin) { FactoryBot.create(:admin) }
  let(:current_ability) { Ability.new(admin) }

  it "can be viewed by admin users" do
    expect(current_ability.can?(:show, described_class.new)).to be true
  end

  it "has a list of available reports" do
    expect(described_class.all).to eq [:identifiers_to_reconcile]
  end
end
