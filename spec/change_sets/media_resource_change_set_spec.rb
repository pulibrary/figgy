# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MediaResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:scanned_resource) { MediaResource.new(title: 'Test', rights_statement: 'Stuff', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: 'pending') }
  let(:form_resource) { scanned_resource }
  before do
    stub_bibdata(bib_id: '123456')
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
  end

  describe "#rights_statement" do
    let(:form_resource) { MediaResource.new(rights_statement: RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")) }
    it "is singular, required, and converts to an RDF::URI" do
      change_set.prepopulate!

      expect(change_set.rights_statement).to eq RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
      change_set.validate(rights_statement: "")
      expect(change_set).not_to be_valid
      change_set.validate(rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/")
      expect(change_set.rights_statement).to be_instance_of RDF::URI
    end
    context "when given a blank MediaResource" do
      let(:form_resource) { MediaResource.new }
      it "sets a default Rights Statement" do
        change_set.prepopulate!

        expect(change_set.rights_statement).to eq RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
      end
    end
  end

  describe "#workflow" do
    it "has a workflow" do
      change_set.prepopulate!
      expect(change_set.workflow).to be_a(BookWorkflow)
      expect(change_set.workflow.pending?).to be true
    end
  end
end
