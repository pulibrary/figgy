# frozen_string_literal: true
require "rails_helper"

RSpec.describe ScannedResourceDecorator do
  subject(:decorator) { described_class.new(resource) }

  let(:resource) do
    FactoryBot.build(:scanned_resource)
  end

  let(:resource_klass) { ScannedResource }

  it_behaves_like "a Valkyrie::ResourceDecorator"

  describe "#imported_created" do
    let(:resource) do
      FactoryBot.build(:scanned_resource,
                       title: "test title",
                       created: "01/01/1970",
                       imported_metadata: imported_metadata)
    end
    context "with a single date" do
      let(:imported_metadata) { [{ created: Date.parse("01/01/1970") }] }
      it "exposes a formatted string for the created date" do
        expect(decorator.imported_created).to eq ["January 1, 1970"]
      end
    end
    context "with a date range" do
      let(:imported_metadata) { [{ created: "1941-01-01T00:00:00Z/1985-12-31T23:59:59Z" }] }
      it "maps date to readable string" do
        expect(decorator.imported_created).to eq ["1941-1985"]
      end
    end
  end

  describe "#human_readable_type" do
    context "with a Recording" do
      let(:resource) { FactoryBot.build(:scanned_resource, change_set: "recording") }
      it "returns Recording" do
        expect(decorator.human_readable_type).to eq "Recording"
      end
    end
    context "with a Recording descriptive proxy" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, change_set: "recording", member_ids: [child.id]) }
      let(:child) { FactoryBot.create_for_repository(:scanned_resource, change_set: "recording") }
      it "returns Recording" do
        expect(decorator.human_readable_type).to eq "Recording"
      end
    end
  end

  context "with a holding location" do
    let(:resource) do
      FactoryBot.build(:scanned_resource,
                       holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/15")
    end
    describe "Voyager downtime" do
      it "handles error caused by Voyager downtime" do
        stub_request(:get, "https://bibdata.princeton.edu/locations/digital_locations.json")
          .to_return(status: 502)
        expect(resource.decorate.rendered_holding_location).to eq([])
      end
    end

    it "exposes markup for rendered holding_location" do
      expect(resource.decorate.rendered_holding_location.first).to eq("Firestone Library")
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
      file_sets = decorator.decorated_file_sets
      expect(file_sets.map(&:id)).to eq [member2.id]
      expect(file_sets.map(&:class)).to eq [FileSetDecorator]
    end
  end

  describe "#decorated_parent" do
    let(:member) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [resource.id]) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
    it "retrieves the parent, decorated" do
      member
      parent = decorator.decorated_parent
      expect(parent.id).to eq member.id
      expect(parent.class).to eq described_class
    end
  end

  describe "#pdf_file" do
    context "when there is a pdf and it exists" do
      before do
        allow(derivs).to receive(:find_by).with(id: file_id).and_return(file_id)
      end
      let(:derivs)   { Valkyrie::StorageAdapter.find(:derivatives) }
      let(:file_id)  { Valkyrie::ID.new("disk:///tmp/stubbed.tif") }
      let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: [file_id] }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, file_metadata: [pdf_file]) }
      it "finds the pdf file" do
        expect(decorator.pdf_file).to eq pdf_file
      end
    end

    context "when there is a pdf but it does not exist" do
      before do
        allow(derivs).to receive(:find_by).with(id: file_id).and_raise(Valkyrie::StorageAdapter::FileNotFound)
      end
      let(:derivs)   { Valkyrie::StorageAdapter.find(:derivatives) }
      let(:file_id)  { Valkyrie::ID.new("disk:///tmp/stubbed.tif") }
      let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: [file_id] }
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource, file_metadata: [pdf_file]) }
      it "does not return the bogus pdf file" do
        expect(decorator.pdf_file).to be nil
      end
    end

    context "when there is no pdf file" do
      let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
      it "returns nil" do
        expect(decorator.pdf_file).to be nil
      end
    end
  end

  describe "#rendered_actors" do
    context "when given groupings of actors along with RDF literals" do
      let(:resource) do
        FactoryBot.create_for_repository(
          :scanned_resource,
          actor: [
            RDF::Literal.new("Test", language: "eng-Latn"),
            Grouping.new(
              elements: [
                "Test",
                "Test2"
              ]
            )
          ]
        )
      end
      it "returns all elements in order for rendering as strings" do
        expect(decorator.rendered_actors).to eq [
          "Test", "Test", "Test2"
        ]
      end
    end
  end

  describe "#rendered_date_range" do
    let(:resource) do
      FactoryBot.create_for_repository(
        :scanned_resource,
        date_range: DateRange.new(start: "1902", end: "1927")
      )
    end
    it "renders the date range as per the date range decorator" do
      expect(decorator.rendered_date_range).to eq "1902-1927"
    end
  end

  describe "#playlists" do
    it "returns all playlists that come from a recording" do
      file_set = FactoryBot.create_for_repository(:file_set)
      proxy_file_set = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_set.id)
      recording = FactoryBot.create_for_repository(:recording, member_ids: file_set.id)
      playlist = FactoryBot.create_for_repository(:playlist, member_ids: proxy_file_set.id)

      decorator = described_class.new(recording)

      expect(decorator.playlists.map(&:id)).to eq [playlist.id]
    end
  end

  it "has a downloadable attribute" do
    expect(decorator.downloadable).to eq ["public"]
  end

  describe "#fixity_map" do
    context "when there's a failed FileSet" do
      it "returns 0 => 1" do
        file_set = FactoryBot.create_for_repository(
          :file_set,
          file_metadata: {
            fixity_success: 0,
            use: Valkyrie::Vocab::PCDMUse.OriginalFile
          }
        )
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: file_set.id)

        decorator = described_class.new(resource)

        expect(decorator.fixity_map).to eq(0 => 1)
      end
    end
    context "when there's a successful file set" do
      it "returns 1 => 1" do
        file_set = FactoryBot.create_for_repository(
          :file_set,
          file_metadata: {
            fixity_success: 1,
            use: Valkyrie::Vocab::PCDMUse.OriginalFile
          }
        )
        resource = FactoryBot.create_for_repository(:scanned_resource, member_ids: file_set.id)

        decorator = described_class.new(resource)

        expect(decorator.fixity_map).to eq(1 => 1)
      end
    end
  end

  describe "#cloud_fixity_summary" do
    it "returns a cloud fixity summary" do
      fs1 = create_file_set(cloud_fixity_success: false)
      fs2 = create_file_set(cloud_fixity_success: false)
      fs3 = create_file_set(cloud_fixity_success: false)
      ok_fs = create_file_set(cloud_fixity_success: true)
      unchecked_fs = FactoryBot.create_for_repository(:file_set)
      # Unrelated FS
      create_file_set(cloud_fixity_success: false)
      volume1 = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs1.id, unchecked_fs.id])
      volume2 = FactoryBot.create_for_repository(:scanned_resource, member_ids: [fs2.id, ok_fs.id])
      mvw = FactoryBot.create_for_repository(:scanned_resource, member_ids: [volume1.id, volume2.id, fs3.id])

      decorator = described_class.new(mvw)

      expect(decorator.cloud_fixity_summary).to eq(
        "<div>failed <span title=\"failed\" class=\"fixity-count label label-warning\">3</span></div>" \
        " <div>succeeded <span title=\"succeeded\" class=\"fixity-count label label-primary\">1</span></div>" \
        " <div>in progress <span title=\"in progress\" class=\"fixity-count label label-info\">1</span></div>"
      )
    end

    def create_file_set(cloud_fixity_success: true)
      file_set = FactoryBot.create_for_repository(:file_set)
      metadata_node = FileMetadata.new(id: SecureRandom.uuid)
      preservation_object = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id, metadata_node: metadata_node)
      if cloud_fixity_success
        # Create an old failure, to guard for the case where it failed and we
        # fixed it.
        FactoryBot.create_for_repository(:event, type: :cloud_fixity, status: "FAILURE", resource_id: preservation_object.id, child_id: metadata_node.id, child_property: :metadata_node)
        FactoryBot.create_for_repository(:event, type: :cloud_fixity, status: "SUCCESS", resource_id: preservation_object.id, child_id: metadata_node.id, child_property: :metadata_node)
      else
        # Create an old success, to guard for the case where it once succeeded
        # and now it failed.
        FactoryBot.create_for_repository(:event, type: :cloud_fixity, status: "SUCCESS", resource_id: preservation_object.id, child_id: metadata_node.id, child_property: :metadata_node)
        FactoryBot.create_for_repository(:event, type: :cloud_fixity, status: "FAILURE", resource_id: preservation_object.id, child_id: metadata_node.id, child_property: :metadata_node)
      end
      file_set
    end
  end
end
