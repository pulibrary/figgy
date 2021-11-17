# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Numismatic Ingest", js: true do
  describe "auto-ingest" do
    context "when there are matching files" do
      it "displays an auto-ingest button" do
        user = FactoryBot.create(:admin)
        coin = FactoryBot.create_for_repository(:coin, coin_number: 1234)

        sign_in user
        visit file_manager_numismatics_coin_path(id: coin.id)

        expect(page).to have_button "Auto Ingest"
      end
    end
  end
end
