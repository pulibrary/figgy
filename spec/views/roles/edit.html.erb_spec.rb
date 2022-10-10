# frozen_string_literal: true
require "rails_helper"

RSpec.describe "roles/edit" do
  let(:admin_user) { FactoryBot.create(:admin) }

  it "doesn't have a form to change the role" do
    staff_role = Role.where(name: "staff").first_or_create

    assign :role, staff_role
    sign_in admin_user
    render

    expect(rendered).not_to have_selector("form[class='edit_role']")
  end
end
