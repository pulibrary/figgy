# frozen_string_literal: true

require "rails_helper"

describe Numismatics::ReferenceWayfinder do
  subject(:numismatic_reference_wayfinder) { described_class.new(resource: numismatic_reference) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  let(:numismatic_reference) do
    res1 = Numismatics::Reference.new(title: "reference1")
    res2 = Numismatics::Reference.new(title: "reference2")
    ch1 = Numismatics::ReferenceChangeSet.new(res1)
    ch2 = Numismatics::ReferenceChangeSet.new(res2)
    change_set_persister.save(change_set: ch1)
    change_set_persister.save(change_set: ch2)
  end

  describe "#references_count" do
    it "returns the number of all the references" do
      expect(numismatic_reference_wayfinder.references_count).to eq 2
    end
  end
end
