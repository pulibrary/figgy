# frozen_string_literal: true
require "rails_helper"

describe Numismatics::ArtistWayfinder do
  subject(:numismatic_artist_wayfinder) { described_class.new(resource: numismatic_artist) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:person_id) { Valkyrie::ID.new(SecureRandom.uuid) }
  let(:numismatic_artist) { FactoryBot.create_for_repository(:numismatic_artist, person_id: person_id) }

  describe "#decorated_person" do
    context "when the person does not exist" do
      it "returns nil" do
        expect(numismatic_artist_wayfinder.decorated_person).to be_nil
      end
    end
  end
end
