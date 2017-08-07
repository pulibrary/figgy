# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Home Page" do
  let(:user) { FactoryGirl.create(:admin) }
  before do
    sign_in user
  end

  it "displays creation links for administrators" do
    expect(page).to have_link "New Scanned Resource"
    expect(page).to have_link "Add a Collection", href: "/collections/new"
    expect(page).to have_link "Manage Roles"
  end
end
