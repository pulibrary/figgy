# frozen_string_literal: true
require "rails_helper"

RSpec.describe Report do
  let(:admin) { FactoryBot.create(:admin) }
  let(:current_ability) { Ability.new(admin) }

  it "can be viewed by admin users" do
    expect(current_ability.can?(:show, described_class.new)).to be true
  end

  it "has a list of available reports" do
    expect(described_class.all).to eq [:ephemera_data, :identifiers_to_reconcile, :pulfa_ark_report, :collection_item_and_image_count, :dpul_success_dashboard]
  end
end
