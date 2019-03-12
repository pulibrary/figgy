# frozen_string_literal: true
require "rails_helper"

RSpec.describe MetadataFormHelper, type: :helper do
  describe "form_title" do
    it "constructs a title for a new object" do
      params = { "action" => "new", "controller" => "scanned_resources" }
      expect(helper.form_title(params)).to eq "New scanned resource"
    end
    it "constructs a title for editing an object" do
      params = { "action" => "edit", "controller" => "ephemera_folders" }
      expect(helper.form_title(params)).to eq "Edit ephemera folder"
    end
    it "constucts a title for a new recording" do
      params = { "change_set" => "recording", "action" => "new", "controller" => "scanned_resources" }
      expect(helper.form_title(params)).to eq "New recording"
    end
    it "constucts a title for editing a recording" do
      params = { "change_set" => "recording", "action" => "edit", "controller" => "scanned_resources" }
      expect(helper.form_title(params)).to eq "Edit recording"
    end
  end
end
