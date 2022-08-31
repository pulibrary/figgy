# frozen_string_literal: true
require "rails_helper"

RSpec.describe SimpleChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:resource_klass) { ScannedResource }
  let(:resource) { resource_klass.new(title: "Test", rights_statement: rights_statement, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: "draft") }
  let(:rights_statement) { RightsStatements.no_known_copyright }
  let(:form_resource) { resource }

  it_behaves_like "a ChangeSet"
  it_behaves_like "a ChangeSet with EmbargoDate"

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(DraftCompleteWorkflow)
      expect(change_set.workflow.draft?).to be true
    end
  end

  describe "date_range mixin" do
    it "is included" do
      expect { change_set.date_range }.not_to raise_error
    end
  end

  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "public"
    end
  end
end
