# frozen_string_literal: true
require "rails_helper"

describe Numismatics::ProvenanceWayfinder do
  subject(:numismatic_provenance_wayfinder) { described_class.new(resource: numismatic_provenance) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:firm_id) { Valkyrie::ID.new(SecureRandom.uuid) }
  let(:person_id) { Valkyrie::ID.new(SecureRandom.uuid) }
  let(:numismatic_provenance) { FactoryBot.create_for_repository(:numismatic_provenance, firm_id: firm_id, person_id: person_id) }

  describe "#decorated_firm" do
    context "when the firm does not exist" do
      it "returns nil" do
        expect(numismatic_provenance_wayfinder.decorated_firm).to be_nil
      end
    end
  end

  describe "#decorated_person" do
    context "when the person does not exist" do
      it "returns nil" do
        expect(numismatic_provenance_wayfinder.decorated_person).to be_nil
      end
    end
  end
end
