# frozen_string_literal: true
require "rails_helper"

<<<<<<< HEAD
RSpec.feature "Manage Users" do
=======
RSpec.feature "Manage Users", js: true do
>>>>>>> d8616123... adds lux order manager to figgy
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  context "when an admin adds a new user" do
    it "has provider: 'cas'" do
      visit users_path
      page.fill_in "user_uid", with: "zelda"
<<<<<<< HEAD
      page.click_button "Add User"
=======
      page.find("form.new_user").native.submit
>>>>>>> d8616123... adds lux order manager to figgy

      expect(User.last.uid).to eq "zelda"
      expect(User.last.provider).to eq "cas"
    end
  end
end
