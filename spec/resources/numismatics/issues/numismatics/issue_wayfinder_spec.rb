# frozen_string_literal: true
require "rails_helper"

describe Numismatics::IssueWayfinder do
  subject(:numismatic_issue_wayfinder) { described_class.new(resource: numismatic_issue) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }

  let(:numismatic_issue) do
    res = Numismatics::Issue.new(part: "citation part", number: "citation number")
    ch = Numismatics::IssueChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  describe "#issues_count" do
    it "returns the number of all the issues" do
      expect(numismatic_issue_wayfinder.issues_count).to eq 1
    end
  end
end
