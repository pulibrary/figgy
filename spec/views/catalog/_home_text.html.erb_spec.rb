# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_home_text.html.erb" do
  before do
    sign_in user if user
    render
  end

  context "when the user is an admin" do
    let(:user) { FactoryBot.create(:admin) }

    it "has a link to the fixity dashboard" do
      expect(rendered).to have_link "Fixity Dashboard"
    end
  end

  context "when the user is not an admin" do
    let(:user) { FactoryBot.create(:curator) }

    it "does not have a link to the fixity dashboard" do
      expect(rendered).not_to have_link "Fixity Dashboard"
    end
  end
end
