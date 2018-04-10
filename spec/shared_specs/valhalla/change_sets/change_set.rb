# frozen_string_literal: true
require 'rails_helper'

RSpec.shared_examples 'a Valhalla::ChangeSet' do
  before do
    raise 'change_set must be set with `let(:change_set)`' unless
      defined? change_set
    raise 'resource_klass must be set with `let(:resource_klass)`' unless
      defined? resource_klass
  end

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
    context "when visibility isn't set" do
      let(:form_resource) { resource_klass.new(visibility: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility hasn't been set" do
      let(:form_resource) { resource_klass.new(visibility: nil) }
      it "has a default of public" do
        change_set.prepopulate!
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

    describe "#pdf_type" do
      let(:form_resource) { resource_klass.new }
      it "has a default of 'gray'" do
        change_set.prepopulate!

        expect(change_set.pdf_type).to eq 'gray'
      end
    end

    describe "#rights_statement" do
      let(:form_resource) { resource_klass.new(rights_statement: RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")) }
      it "is singular, required, and converts to an RDF::URI" do
        change_set.prepopulate!

        expect(change_set.rights_statement).to eq RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
        change_set.validate(rights_statement: "")
        expect(change_set).not_to be_valid
        change_set.validate(rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/")
        expect(change_set.rights_statement).to be_instance_of RDF::URI
      end
      context "when given a blank resource" do
        let(:form_resource) { resource_klass.new }
        it "sets a default Rights Statement" do
          change_set.prepopulate!

          expect(change_set.rights_statement).to eq RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
        end
      end
    end

    describe "#viewing_hint" do
      it "is singular" do
        form_resource.viewing_hint = ["Test"]
        change_set.prepopulate!

        expect(change_set.viewing_hint).to eq "Test"
      end
    end

    describe "#viewing_direction" do
      it "is singular" do
        form_resource.viewing_direction = ["Test"]
        change_set.prepopulate!

        expect(change_set.viewing_direction).to eq "Test"
      end
    end
  end
end
