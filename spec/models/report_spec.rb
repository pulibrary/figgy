# frozen_string_literal: true
require "rails_helper"

RSpec.describe Report do
  let(:admin) { FactoryBot.create(:admin) }
  let(:current_ability) { Ability.new(admin) }

  it "can be viewed by admin users" do
    expect(current_ability.can?(:show, described_class.new)).to be true
  end

  it "has a list of available reports" do
<<<<<<< HEAD
    expect(described_class.all).to eq [:ephemera_data, :identifiers_to_reconcile]
=======
    expect(described_class.all).to eq [:identifiers_to_reconcile]
>>>>>>> d8616123... adds lux order manager to figgy
  end
end
