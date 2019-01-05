# frozen_string_literal: true
require "rails_helper"

RSpec.describe SimpleResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:resource_klass) { ScannedResource }
  let(:resource) { resource_klass.new(title: "Test", rights_statement: rights_statement, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: "draft") }
  let(:rights_statement) { RightsStatements.no_known_copyright }
  let(:form_resource) { resource }

  it_behaves_like "a ChangeSet"

  describe "#workflow" do
    it "has a workflow" do
      change_set.prepopulate!
      expect(change_set.workflow).to be_a(DraftCompleteWorkflow)
      expect(change_set.workflow.draft?).to be true
    end
  end
end
