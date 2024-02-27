# frozen_string_literal: true
require "rails_helper"

RSpec.describe Valkyrie::ResourceDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:complete_scanned_resource) }

  describe "#members" do
    let(:child_resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }
    let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: [child_resource.id]) }

    it "retrieves all member resources" do
      expect(decorator.members.to_a).not_to be_empty
    end
  end

  describe "#parents" do
    let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }
    let(:parent_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: [resource.id]) }
    before do
      parent_resource
    end

    it "retrieves all parent resources" do
      expect(decorator.parents.to_a).not_to be_empty
    end
  end

  describe "#iiif_metadata" do
    context "when viewing a new Scanned Resource" do
      let(:resource) do
        FactoryBot.create_for_repository(:complete_scanned_resource,
                                         title: ["test title"],
                                         pdf_type: ["Gray"],
                                         identifier: ["http://arks.princeton.edu/ark:/88435/5m60qr98h"],
                                         created: ["01/01/1970"])
      end
      let(:metadata) { resource.decorate.iiif_metadata }

      it "returns iiif attributes in label/value key/val hash pairs" do
        expect(metadata).to be_an Array
        expect(metadata).to include("label" => "Title", "value" => ["test title"])
        expect(metadata).to include("label" => "Identifier", "value" => \
          ["<a href='http://arks.princeton.edu/ark:/88435/5m60qr98h' alt='Identifier'>http://arks.princeton.edu/ark:/88435/5m60qr98h</a>"])
      end
    end

    context "when viewing an Ephemera Project" do
      let(:resource) { FactoryBot.create_for_repository(:ephemera_project, slug: "lae-d957") }
      let(:metadata) { resource.decorate.iiif_metadata }

      it "returns slug attributes as exhibit" do
        expect(metadata).to be_an Array
        expect(metadata).to include "label" => "Exhibit", "value" => ["lae-d957"]
      end
    end
  end

  describe "#first_title" do
    let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, title: ["There and back again", "A hobbit's tale"]) }

    it "returns the first title" do
      expect(resource.decorate.first_title).to eq "There and back again"
    end
  end

  describe "#merged_titles" do
    let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, title: ["There and back again", "A hobbit's tale"]) }

    it "returns a one-line title string" do
      expect(resource.decorate.merged_titles).to eq "There and back again; A hobbit's tale"
    end
  end

  describe "#titles" do
    let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, title: ["There and back again", "A hobbit's tale"]) }

    it "returns the title array" do
      expect(resource.decorate.titles).to eq ["There and back again", "A hobbit's tale"]
    end
  end

  describe "#member_of_collections_value" do
    let(:collection) { FactoryBot.create_for_repository(:collection, title: "My Nietzsche Collection") }
    let(:resource) do
      FactoryBot.create_for_repository(
        :complete_scanned_resource,
        title: ["Menschliches, Allzumenschliches", "Ein Buch für freie Geister"],
        member_of_collection_ids: collection.id
      )
    end

    it "returns the titles of collections" do
      expect(resource.decorate.iiif_metadata).to include("label" => "Member Of Collections", "value" => ["My Nietzsche Collection"])
    end
  end

  describe "manifestable_state?" do
    describe "for resources without workflows" do
      let(:resource) { FactoryBot.build(:ephemera_term) }
      it "defaults to true" do
        expect(resource.decorate.manifestable_state?).to eq true
      end
    end

    describe "a resource with manifestable workflow state" do
      it "returns true" do
        expect(resource.decorate.manifestable_state?).to eq true
      end
    end

    describe "a resource with non-manifestable workflow state" do
      it "returns false" do
        resource.state = ["metadata_review"]
        expect(resource.decorate.manifestable_state?).to eq false
      end
    end
  end

  describe "public_readable_state?" do
    describe "for resources without workflows" do
      let(:resource) { FactoryBot.build(:ephemera_term) }
      it "defaults to true" do
        expect(resource.decorate.public_readable_state?).to eq true
      end
    end

    describe "a resource with public-readable workflow state" do
      it "returns true" do
        expect(resource.decorate.public_readable_state?).to eq true
      end
    end

    describe "a resource with non-public-readable workflow state" do
      it "returns false" do
        resource.state = ["pending"]
        expect(resource.decorate.public_readable_state?).to eq false
      end
    end
  end

  describe "#form_input_values" do
    let(:resource) { FactoryBot.build(:scanned_resource, title: "Архипела́г ГУЛА́Г") }
    it "generates OpenStruct Objects for select form field values" do
      expect(resource.decorate.form_input_values).to be_an OpenStruct
      expect(resource.decorate.form_input_values.title).to eq "Архипела́г ГУЛА́Г"
      expect(resource.decorate.form_input_values.id).to eq resource.id.to_s
    end
  end

  describe "#ark_mintable_state?" do
    context "with a completed SimpleResource" do
      let(:resource) { FactoryBot.build(:complete_simple_resource) }
      it "returns true" do
        expect(resource.decorate.ark_mintable_state?).to eq true
      end
    end

    context "with a complete Multi-Volume Work" do
      let(:resource) { FactoryBot.build(:complete_scanned_resource) }
      it "returns true" do
        expect(resource.decorate.ark_mintable_state?).to eq true
      end
    end

    context "with an EphemeraBox" do
      let(:resource) { FactoryBot.build(:ephemera_box) }
      it "returns false" do
        expect(resource.decorate.ark_mintable_state?).to eq false
      end
    end

    context "with an EphemeraFolder" do
      let(:resource) { FactoryBot.build(:ephemera_folder) }
      it "returns false" do
        expect(resource.decorate.ark_mintable_state?).to eq false
      end
    end

    context "when a resource is without a workflow" do
      let(:resource) { FactoryBot.build(:ephemera_term) }
      it "defaults to false" do
        expect(resource.decorate.ark_mintable_state?).to eq false
      end
    end
  end

  describe "#workflow_class" do
    context "when no ChangeSet can be found" do
      let(:resource) { MyResource.new }

      before do
        class MyResource < Resource
        end
      end
      it "raises an error" do
        expect { decorator.workflow_class }.to raise_error(WorkflowRegistry::EntryNotFound)
      end
      after do
        Object.send(:remove_const, :MyResource)
      end
    end
  end

  describe "#manages_state?" do
    context "scanned resources" do
      it "do manage state" do
        expect(decorator.manages_state?).to be true
      end
    end

    context "ephemera terms" do
      let(:resource) { FactoryBot.build(:ephemera_term) }

      it "do not manage state" do
        expect(decorator.manages_state?).to be false
      end
    end
  end

  describe "#visibility" do
    context "complete open resource" do
      let(:resource) { FactoryBot.build(:complete_scanned_resource) }

      it "has a public notice" do
        expect(decorator.visibility.first).to have_selector("div.alert-success", text: "Users will be able to view this digital object on discovery sites.")
      end
    end

    context "pending open resource" do
      let(:resource) { FactoryBot.build(:pending_scanned_resource) }

      it "has a warning about the workflow" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites due to the workflow status.")
      end
    end
    
    context "needs_qa open resource" do
      let(:resource) { FactoryBot.build(:needs_qa_ephemera_folder) }

      it "has a warning about the workflow" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites due to the workflow status.")
      end
    end

    context "complete netid resource" do
      let(:resource) { FactoryBot.build(:complete_campus_only_scanned_resource) }
      it "has a login-required notice" do
        expect(decorator.visibility.first).to have_selector("div.alert-info", text: "Users will be able to view this digital object on discovery sites if they log in with CAS.")
      end
    end

    context "pending netid resource" do
      let(:resource) { FactoryBot.build(:pending_campus_only_scanned_resource) }

      it "has a warning about the workflow" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites due to the workflow status.")
      end
    end

    context "complete campus ip resource" do
      let(:resource) { FactoryBot.build(:complete_campus_ip_scanned_resource) }

      it "has a location notice" do
        note = "Users will be able to view this digital object on discovery sites if they are on campus or logged in to campus VPN."
        expect(decorator.visibility.first).to have_selector("div.alert-info", text: note)
      end
    end

    context "pending campus ip resource" do
      let(:resource) { FactoryBot.build(:pending_campus_ip_scanned_resource) }

      it "has a warning about the workflow" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites due to the workflow status.")
      end
    end

    context "complete reading room resource" do
      let(:resource) { FactoryBot.build(:complete_reading_room_scanned_resource) }
      it "has a permissions / location notice" do
        note = "Permitted users will be able to view this digital object on discovery sites if they are in the RBSC reading room."
        expect(decorator.visibility.first).to have_selector("div.alert-info", text: note)
      end
    end

    context "pending reading room resource" do
      let(:resource) { FactoryBot.build(:pending_reading_room_scanned_resource) }

      it "has a warning about the workflow" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites due to the workflow status.")
      end
    end

    context "complete private resource" do
      let(:resource) { FactoryBot.build(:complete_scanned_resource, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE) }

      it "has a permissions notice" do
        expect(decorator.visibility.first).to have_selector("div.alert-info", text: "Permitted users will be able to view this digital object on discovery sites if they log in with CAS.")
      end
    end

    context "pending private resource" do
      let(:resource) { FactoryBot.build(:pending_scanned_resource, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE) }

      it "has a warning about the workflow" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites due to the workflow status.")
      end
    end

    context "complete embargoed resource" do
      let(:date) { (Time.zone.today + 2).strftime("%-m/%-d/%Y") }
      let(:resource) { FactoryBot.build(:complete_scanned_resource, embargo_date: date) }

      it "has a warning about the embargo status" do
        expect(decorator.visibility.first).to have_selector("div.alert-warning", text: "Users will not be able to view this digital object on discovery sites because the resource is embargoed.")
      end
    end
  end
  describe "#visibility_badge" do
    let(:resource) { FactoryBot.build(:complete_scanned_resource) }

    it "has a badge" do
      expect(decorator.visibility_badge.first).to have_selector("div.badge-success", text: "open")
    end

    it "does not have a verbose note" do
      expect(decorator.visibility_badge.first).not_to have_selector("div.alert")
    end
  end
  describe "#visible?" do
    it "determines whether or not a resource is visible" do
      expect(decorator.visible?).to be true
    end

    context "when a resource is set to private" do
      let(:resource) { FactoryBot.build(:complete_private_scanned_resource) }

      it "is not visible" do
        expect(decorator.visible?).to be false
      end
    end
  end
  describe "#downloadable?" do
    it "determines whether or not a decorated resource can be downloaded" do
      expect(decorator.downloadable?).to be true
    end

    context "when the resource has the downloadable attribute set to none" do
      let(:resource) { FactoryBot.build(:complete_scanned_resource, downloadable: ["none"]) }

      it "does not allow downloads" do
        expect(decorator.downloadable?).to be false
      end
    end

    context "when the resource has a nil downloadable attribute" do
      let(:resource) { FactoryBot.build(:complete_scanned_resource, downloadable: nil) }

      it "delegates to whether unauthenicated users can access the resource" do
        expect(decorator.downloadable?).to eq(decorator.visible? && decorator.public_readable_state?)
      end
    end

    context "with a coin resource" do
      let(:resource) { FactoryBot.build(:complete_open_coin) }

      it "allows downloads" do
        expect(decorator.downloadable?).to be true
      end
    end
  end
end
