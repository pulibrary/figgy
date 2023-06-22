# frozen_string_literal: true
require "rails_helper"

describe Numismatics::CitationWayfinder do
  subject(:numismatic_citation_wayfinder) { described_class.new(resource: numismatic_citation) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_reference) { FactoryBot.create_for_repository(:numismatic_reference) }
  let(:numismatic_reference_id) { numismatic_reference.id }
  let(:numismatic_citation) do
    res = Numismatics::Citation.new(title: "athens", numismatic_reference_id: numismatic_reference_id)
    ch = Numismatics::CitationChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end
  let(:coin) do
    res = Numismatics::Coin.new(title: "hercules", weight: 5, numismatic_citation: [numismatic_citation])
    ch = Numismatics::CoinChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  before do
    coin
  end

  describe "#decorated_numismatic_reference" do
    it "returns a decorated numismatic reference" do
      expect(numismatic_citation_wayfinder.decorated_numismatic_reference).to eq numismatic_reference.decorate
    end

    context "when the numismatic reference does not exist" do
      let(:numismatic_reference_id) { Valkyrie::ID.new(SecureRandom.uuid) }

      it "returns nil" do
        expect(numismatic_citation_wayfinder.decorated_numismatic_reference).to be_nil
      end
    end
  end
end
