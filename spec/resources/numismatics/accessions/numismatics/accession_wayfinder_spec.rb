# frozen_string_literal: true
require "rails_helper"

describe Numismatics::AccessionWayfinder do
  subject(:numismatic_accession_wayfinder) { described_class.new(resource: numismatic_accession) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_accession) { FactoryBot.create_for_repository(:numismatic_accession) }

  let(:numismatic_accession) do
    res = Numismatics::Accession.new(title: "athens")
    ch = Numismatics::AccessionChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  describe "#accessions_count" do
    it "returns the number of all the accessions" do
      expect(numismatic_accession_wayfinder.accessions_count).to eq 1
    end
  end
end
