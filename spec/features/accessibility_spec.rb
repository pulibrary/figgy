require "rails_helper"

describe "accessibility", type: :feature, js: true do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  context "home page" do
    it "complies with WCAG" do
      visit "/"

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#site-actions")
    end
  end
end
