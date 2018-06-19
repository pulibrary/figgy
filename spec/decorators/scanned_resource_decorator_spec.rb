# frozen_string_literal: true
require "rails_helper"

RSpec.describe ScannedResourceDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:scanned_resource) }
  let(:resource_klass) { ScannedResource }

  it_behaves_like "a Valkyrie::ResourceDecorator"

  describe "#imported_created" do
    let(:resource) do
      FactoryBot.build(:scanned_resource,
                       title: "test title",
                       created: "01/01/1970",
                       imported_metadata: [{
                         creator: "test creator",
                         created: Date.parse("01/01/1970")
                       }])
    end
    it "exposes a formatted string for the created date" do
      expect(decorator.imported_created).to eq ["January 1, 1970"]
    end
  end
  context "with imported metadata" do
    let(:resource) do
      FactoryBot.build(:scanned_resource,
                       title: "test title",
                       author: "test author",
                       imported_metadata: [{
                         creator: "test creator",
                         subject: "test subject",
                         language: "eng",
                         location: ["RCPPA BL980.G7 B66 1982"]
                       }])
    end
    describe "#iiif_manifest_attributes" do
      it "returns attributes merged with the imported metadata for the IIIF Manifest" do
        expect(decorator.iiif_manifest_attributes).to include title: ["test title"]
        expect(decorator.iiif_manifest_attributes).to include author: ["test author"]
        expect(decorator.iiif_manifest_attributes).to include creator: ["test creator"]
        expect(decorator.iiif_manifest_attributes).to include subject: ["test subject"]
        expect(decorator.iiif_manifest_attributes).to include location: ["RCPPA BL980.G7 B66 1982"]
      end
    end
    describe "#display_imported_language" do
      it "maps keys to english strings" do
        expect(decorator.display_imported_language).to eq ["English"]
      end
    end
    describe "raw imported metadata" do
      it "is not displayed" do
        expect(decorator.display_attributes.keys).not_to include :source_metadata
      end
    end
  end

  describe "#parents" do
    let(:parent_collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [parent_collection.id]) }

    before do
      parent_collection
    end

    it "retrieves all parent resources" do
      expect(decorator.parents.to_a).not_to be_empty
      expect(decorator.parents.first).to be_a Collection
      expect(decorator.parents.first.id).to eq parent_collection.id
    end
  end

  describe "#members" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member.id]) }
    let(:member) { FactoryBot.create_for_repository(:scanned_resource) }
    it "retrieves all members" do
      members = decorator.members
      expect(members.map(&:id)).to eq [member.id]
      expect(members.map(&:class)).to eq [ScannedResource]
    end
  end

  describe "#volumes" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member.id, member2.id]) }
    let(:member) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:member2) { FactoryBot.create_for_repository(:file_set) }
    it "returns all ScannedResource members, decorated" do
      volumes = decorator.volumes
      expect(volumes.map(&:id)).to eq [member.id]
      expect(volumes.map(&:class)).to eq [described_class]
    end
  end

  describe "#file_sets" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [member.id, member2.id]) }
    let(:member) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:member2) { FactoryBot.create_for_repository(:file_set) }
    it "returns all FileSet members, decorated" do
      file_sets = decorator.file_sets
      expect(file_sets.map(&:id)).to eq [member2.id]
      expect(file_sets.map(&:class)).to eq [FileSetDecorator]
    end
  end

  describe "#decorated_parent_resource" do
    let(:member) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [resource.id]) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
    it "retrieves the parent, decorated" do
      member
      parent = decorator.decorated_parent_resource
      expect(parent.id).to eq member.id
      expect(parent.class).to eq described_class
    end
  end
end
