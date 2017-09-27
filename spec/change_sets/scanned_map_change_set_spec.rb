# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedMapChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:scanned_map) { ScannedMap.new(title: 'Test', rights_statement: 'Stuff', visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: 'pending') }
  let(:form_resource) { scanned_map }
  before do
    stub_bibdata(bib_id: '123456')
  end

  describe "#workflow" do
    it "has a workflow" do
      change_set.prepopulate!
      expect(change_set.workflow).to be_a(BookWorkflow)
      expect(change_set.workflow.pending?).to be true
    end
  end
end
