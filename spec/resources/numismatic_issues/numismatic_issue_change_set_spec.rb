# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticIssueChangeSet do
  subject(:change_set) { described_class.new(issue) }
  let(:issue) { FactoryBot.build(:numismatic_issue) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to be_a(Hash)
      expect(change_set.primary_terms.keys).to eq(["", "Place", "Obverse", "Reverse", "Rights and Notes", "Artists and Subjects"])
      expect(change_set.primary_terms[""]).to include(:object_type, :denomination, :metal, :workshop)
      expect(change_set.primary_terms.values.flatten).not_to include(:issue_number)
    end
  end

  describe "#visibility" do
    it "exposes the visibility" do
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "can update the visibility" do
      change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  describe "#state" do
    it "pre-populates" do
      expect(change_set.state).to eq "draft"
    end

    context "when an issue has coin members" do
      subject(:change_set) { described_class.new(issue) }
      let(:coin) { FactoryBot.create_for_repository(:coin) }
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id]) }
      let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
      end
      it "propagates the state to member resources" do
        change_set.state = "complete"
        persisted = change_set_persister.save(change_set: change_set)
        coins = persisted.decorate.decorated_coins
        expect(coins.first.state).to eq "complete"
      end
    end
  end

  describe "validations" do
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.validate(member_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_ids: ["55a14e79-710d-42c1-86aa-3d8cdaa62930"])
        expect(change_set).not_to be_valid
      end
    end
  end

  describe "date_range mixin" do
    it "is included" do
      expect { change_set.date_range }.not_to raise_error NoMethodError
    end
  end

  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "public"
    end
  end

  describe "#place" do
    it "can be set with a city, state, and region" do
      change_set.validate(place: [{ city: "City", state: "State", region: "Region" }])
      expect(change_set.place.first.city).to eq "City"
      expect(change_set.place.first.state).to eq "State"
      expect(change_set.place.first.region).to eq "Region"
      # Ensure form builder works.
      change_set.place = []
      change_set.validate("place_attributes" => { "0" => { city: "City2", state: "State", region: "Region" } })
      expect(change_set.place.first.city).to eq "City2"
      # Ensure it doesn't result in an empty object if nothing is set
      change_set.place = []
      change_set.validate(place: [{ city: nil, state: nil, region: nil }])
      change_set.sync
      expect(change_set.resource.place).to be_empty
    end
  end

  describe "#prepopulate!" do
    it "builds an empty numsimatic place" do
      change_set.prepopulate!
      expect(change_set.place.first).to be_a NumismaticPlaceChangeSet
    end
  end
end
