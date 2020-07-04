# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_show_header_default.html.erb" do
  context "when the user can't update the resource" do
    before do
      allow(view).to receive(:render_document_heading)
    end
    it "doesn't show a claim button" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = ChangeSet.for(resource)
      assign :change_set, change_set

      render partial: "catalog/show_header_default", locals: { resource: resource, document: {} }
      expect(rendered).not_to have_button "Claim"
    end
  end
  context "when the user can update the resource" do
    let(:user) { FactoryBot.create(:admin) }
    before do
      sign_in(user)
      allow(view).to receive(:render_document_heading)
    end
    it "shows a claim button" do
      resource = FactoryBot.create_for_repository(:scanned_resource)
      change_set = ChangeSet.for(resource)
      assign :change_set, change_set

      render partial: "catalog/show_header_default", locals: { resource: resource, document: {} }
      expect(rendered).to have_button "Claim"
      expect(rendered).to have_selector "input[type='hidden'][name='scanned_resource[claimed_by]'][value='#{user.uid}']", visible: false
    end
    it "shows a claim button if already claimed by someone else" do
      resource = FactoryBot.create_for_repository(:scanned_resource, claimed_by: "Michaelangelo")
      change_set = ChangeSet.for(resource)
      assign :change_set, change_set

      render partial: "catalog/show_header_default", locals: { resource: resource, document: {} }
      expect(rendered).to have_button "Claim from Michaelangelo"
      expect(rendered).to have_selector "input[type='hidden'][name='scanned_resource[claimed_by]'][value='#{user.uid}']", visible: false
    end
    it "shows an Unclaim button if claimed by them" do
      resource = FactoryBot.create_for_repository(:scanned_resource, claimed_by: user.uid)
      change_set = ChangeSet.for(resource)
      assign :change_set, change_set

      render partial: "catalog/show_header_default", locals: { resource: resource, document: {} }
      expect(rendered).to have_button "Unclaim"
      expect(rendered).to have_selector "input[type='hidden'][name='scanned_resource[claimed_by]'][value='']", visible: false
    end
  end
end
