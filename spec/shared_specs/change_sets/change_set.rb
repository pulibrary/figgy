# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a ChangeSet" do
  before do
    raise "change_set must be set with `let(:change_set)`" unless
      defined? change_set
    raise "resource_klass must be set with `let(:resource_klass)`" unless
      defined? resource_klass
  end

  describe "#validate!" do
    it "doesn't make it look changed if passed an empty hash" do
      expect(change_set).not_to be_changed
      change_set.validate({})
      expect(change_set).not_to be_changed
    end
  end

  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end

    context "when title is an empty array" do
      it "is invalid" do
        expect(change_set.validate(title: [])).to eq false
      end
    end
    context "when rights_statement isn't set" do
      let(:form_resource) { resource_klass.new(rights_statement: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility is blank" do
      let(:form_resource) { resource_klass.new(visibility: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility hasn't been set" do
      let(:form_resource) { resource_klass.new(visibility: nil) }
      it "has a default of public" do
        expect(change_set.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
    context "when given a bad viewing direction" do
      it "is invalid" do
        change_set.validate(viewing_direction: "backwards-to-forwards")
        expect(change_set).not_to be_valid
      end
    end
    context "when given a good viewing direction" do
      it "is valid" do
        change_set.validate(viewing_direction: "left-to-right")
        expect(change_set).to be_valid
      end
    end
    context "when given a bad viewing hint" do
      it "is invalid" do
        change_set.validate(viewing_hint: "bananas")
        expect(change_set).not_to be_valid
      end
    end
    context "when given a good viewing direction" do
      it "is valid" do
        change_set.validate(viewing_hint: "paged")
        expect(change_set).to be_valid
      end
    end
    context "when given a non-UUID for a collection" do
      it "is not valid" do
        change_set.validate(member_of_collection_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a collection which does not exist" do
      it "is not valid" do
        change_set.validate(member_of_collection_ids: ["b8823acb-d42b-4e62-a5c9-de5f94cbd3f6"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.validate(member_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_ids: ["55a14e79-710d-42c1-86aa-3d8cdaa62930"])
        expect(change_set).not_to be_valid
      end
    end

    describe "#pdf_type" do
      let(:form_resource) { resource_klass.new }
      it "has a default of 'color'" do
        expect(change_set.pdf_type).to eq "color"
      end
    end

    describe "#rights_statement" do
      let(:form_resource) { resource_klass.new(rights_statement: RightsStatements.no_known_copyright) }
      it "is singular, required, and converts to an RDF::URI" do
        expect(change_set.rights_statement).to eq RightsStatements.no_known_copyright
        change_set.validate(rights_statement: "")
        expect(change_set).not_to be_valid
        change_set.validate(rights_statement: RightsStatements.no_known_copyright.to_s)
        expect(change_set.rights_statement).to be_instance_of RDF::URI
      end
      context "when given a blank resource" do
        let(:form_resource) { resource_klass.new }
        it "sets a default Rights Statement" do
          expect(change_set.rights_statement).to eq RightsStatements.no_known_copyright
        end
      end
    end

    describe "#viewing_hint" do
      it "is singular" do
        form_resource.viewing_hint = ["Test"]

        expect(change_set.viewing_hint).to eq "Test"
      end
    end

    describe "#viewing_direction" do
      it "is singular" do
        form_resource.viewing_direction = ["Test"]

        expect(change_set.viewing_direction).to eq "Test"
      end
    end
  end
end
