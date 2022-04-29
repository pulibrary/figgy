# frozen_string_literal: true
require "rails_helper"

describe Numismatics::FirmWayfinder do
  subject(:numismatic_firm_wayfinder) { described_class.new(resource: numismatic_firm) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_firm) { FactoryBot.create_for_repository(:numismatic_firm) }

  let(:numismatic_firm) do
    res = Numismatics::Firm.new(title: "athens")
    ch = Numismatics::FirmChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  describe "#firms_count" do
    it "returns the number of all the firms" do
      expect(numismatic_firm_wayfinder.firms_count).to eq 1
    end
  end
end
