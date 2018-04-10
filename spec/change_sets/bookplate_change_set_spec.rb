# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BookplateChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:bookplate) { Bookplate.new(title: 'Test', rights_statement: 'Stuff', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: 'pending') }
  let(:form_resource) { bookplate }

  describe "#prepopulate!" do
    it "doesn't make it look changed" do
      expect(change_set).not_to be_changed
      change_set.prepopulate!
      expect(change_set).not_to be_changed
    end
  end
  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
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
    context "when title is an empty array" do
      it "is invalid" do
        expect(change_set.validate(title: [])).to eq false
      end
    end
    context "when rights_statement isn't set" do
      let(:form_resource) { bookplate.new(rights_statement: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility isn't set" do
      let(:form_resource) { bookplate.new(visibility: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility hasn't been set" do
      let(:form_resource) { bookplate.new(visibility: nil) }
      it "has a default of public" do
        change_set.prepopulate!
        expect(change_set.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
    describe "#viewing_hint" do
      it "is singular" do
        bookplate.viewing_hint = ["Test"]
        change_set.prepopulate!

        expect(change_set.viewing_hint).to eq "Test"
      end
    end

    describe "#viewing_direction" do
      it "is singular" do
        bookplate.viewing_direction = ["Test"]
        change_set.prepopulate!

        expect(change_set.viewing_direction).to eq "Test"
      end
    end

    describe "#pdf_type" do
      let(:form_resource) { Bookplate.new }
      it "has a default of 'gray'" do
        change_set.prepopulate!

        expect(change_set.pdf_type).to eq 'gray'
      end
    end

    describe "#rights_statement" do
      let(:form_resource) { Bookplate.new(rights_statement: RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")) }
      it "is singular, required, and converts to an RDF::URI" do
        change_set.prepopulate!

        expect(change_set.rights_statement).to eq RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
        change_set.validate(rights_statement: "")
        expect(change_set).not_to be_valid
        change_set.validate(rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/")
        expect(change_set.rights_statement).to be_instance_of RDF::URI
      end
      context "when given a blank Bookplate" do
        let(:form_resource) { Bookplate.new }
        it "sets a default Rights Statement" do
          change_set.prepopulate!

          expect(change_set.rights_statement).to eq RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
        end
      end
    end

    describe "#logical_structure" do
      let(:structure) do
        {
          "label": "Top!",
          "nodes": [
            {
              "label": "Chapter 1",
              "nodes": [
                {
                  "proxy": resource1.id
                }
              ]
            },
            {
              "label": "Chapter 2",
              "nodes": [
                {
                  "proxy": resource2.id
                }
              ]
            }
          ]
        }
      end
      let(:resource1) { FactoryBot.create_for_repository(:file_set) }
      let(:resource2) { FactoryBot.create_for_repository(:file_set) }
      it "can set a whole structure all at once" do
        change_set.prepopulate!
        expect(change_set.validate(logical_structure: [structure])).to eq true

        expect(change_set.logical_structure[0].label).to eq ["Top!"]
        expect(change_set.logical_structure[0].nodes[0].label).to eq ["Chapter 1"]
        expect(change_set.logical_structure[0].nodes[0].nodes[0].proxy).to eq [resource1.id]
        expect(change_set.logical_structure[0].nodes[1].label).to eq ["Chapter 2"]
        expect(change_set.logical_structure[0].nodes[1].nodes[0].proxy).to eq [resource2.id]
      end
      it "has a default label" do
        change_set.prepopulate!

        expect(change_set.logical_structure[0].label).to eq ["Logical"]
      end
    end
  end
end
