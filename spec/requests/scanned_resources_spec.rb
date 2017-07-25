# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Scanned Resources Management" do
  let(:user) { FactoryGirl.create(:admin) }
  before do
    sign_in user if user
  end
  describe "new" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { get "/concern/scanned_resources/new" }.to raise_error CanCan::AccessDenied
      end
    end
    it "has a form for creating scanned resources" do
      get "/concern/scanned_resources/new"
      expect(response.body).to have_field "Title"
      expect(response.body).to have_field "Source Metadata ID"
      expect(response.body).to have_field "Rights Statement"
      expect(response.body).to have_field "Rights Note"
      expect(response.body).to have_field "Local identifier"
      expect(response.body).to have_field "Holding Location"
      expect(response.body).to have_field "PDF Type"
      expect(response.body).to have_field "Portion Note"
      expect(response.body).to have_field "Navigation Date"
      expect(response.body).to have_checked_field "Private"
      expect(response.body).to have_button "Save"
    end
  end
end
