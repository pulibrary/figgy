# frozen_string_literal: true
require "rails_helper"

RSpec.describe PlaylistChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:playlist) { FactoryBot.build(:playlist) }
  let(:form_resource) { playlist }

  describe "#prepopulate!" do
    it "sets default private visibility" do
      change_set.prepopulate!
      expect(change_set.visibility).to eq visibility
    end
  end

  describe "validations" do
    before do
      change_set.prepopulate!
    end
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
    context "when given a valid UUID for a member resource which does exist" do
      it "is valid" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        change_set.validate(member_ids: [resource.id])
        expect(change_set).to be_valid
      end
    end

    context "title" do
      let(:playlist) { Playlist.new }
      it "is required" do
        expect(change_set).not_to be_valid
        change_set.validate(title: "Some Songs")
        expect(change_set).to be_valid
      end
    end

    context "part_of" do
      it "is set" do
        change_set.validate(part_of: "mustest")
        expect(change_set.part_of).to eq "mustest"
      end
    end
  end

  describe "#primary_terms" do
    it "contains title" do
      expect(change_set.primary_terms).to include :title
    end
    it "contains part_of" do
      expect(change_set.primary_terms).to include :part_of
    end
  end
end
