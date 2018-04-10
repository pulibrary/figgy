# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:resource_klass) { Bookplate }
  let(:scanned_resource) { resource_klass.new(title: 'Test', rights_statement: 'Stuff', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: 'pending') }
  let(:form_resource) { scanned_resource }

  before do
    stub_bibdata(bib_id: '123456')
  end

  it_behaves_like 'a Valhalla::ChangeSet'

  describe "validations" do
    context "when neither title or metadata identifier is set" do
      let(:form_resource) { scanned_resource.new(title: "", source_metadata_identifier: "") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when only metadata_identifier is set" do
      let(:form_resource) { scanned_resource.new(title: "", source_metadata_identifier: "123456") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when given a valid state transition" do
      it "is valid" do
        change_set.validate(state: "metadata_review")
        expect(change_set).to be_valid
      end
    end
    context "when given an invalid state transition" do
      it "is invalid" do
        change_set.validate(state: "complete")
        expect(change_set).not_to be_valid
      end
    end
  end

  describe "#holding_location" do
    it "converts values to RDF::URIs" do
      change_set.prepopulate!
      change_set.validate(holding_location: "http://test.com/")
      expect(change_set.holding_location).to be_instance_of RDF::URI
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
