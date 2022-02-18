# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetadataFormHelper, type: :helper do
  describe "form_title" do
    it "constructs a title for a new object" do
      params = {"action" => "new", "controller" => "scanned_resources"}
      expect(helper.form_title(params)).to eq "New scanned resource"
    end
    it "constructs a title for editing an object" do
      params = {"action" => "edit", "controller" => "ephemera_folders"}
      expect(helper.form_title(params)).to eq "Edit ephemera folder"
    end
    it "will not error if the change_set value is empty" do
      params = {"change_set" => "", "action" => "Edit", "controller" => "scanned_resources"}
      expect(helper.form_title(params)).to eq "Edit scanned resource"
    end
  end
  describe "form_title based on the change_set value" do
    it "constucts a title for a new simple resource" do
      params = {"change_set" => "simple", "action" => "new", "controller" => "scanned_resources"}
      expect(helper.form_title(params)).to eq "New simple resource"
    end
    it "constucts a title for a new recording resource" do
      params = {"change_set" => "recording", "action" => "new", "controller" => "scanned_resources"}
      expect(helper.form_title(params)).to eq "New recording resource"
    end
    it "constucts a title for editing an object" do
      params = {"change_set" => "formal_letters", "action" => "edit", "controller" => "scanned_resources"}
      expect(helper.form_title(params)).to eq "Edit formal letter resource"
    end
  end

  describe "form_title based on the change_set value" do
    it "constucts a title for cases where creating a new resource raises an error" do
      params = {
        "action" => "create",
        "controller" => "scanned_resources",
        "scanned_resource" => {
          "change_set" => "simple"
        }
      }
      expect(helper.form_title(params)).to eq "New simple resource"
    end
  end
end
