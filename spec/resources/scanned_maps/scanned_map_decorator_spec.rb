# frozen_string_literal: true
require "rails_helper"

RSpec.describe ScannedMapDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:imported_coverage) { "northlimit=07.033333; eastlimit=011.583333; southlimit=03.917778; westlimit=008.497222; units=degrees; projection=EPSG:4326" }
  let(:resource) do
    FactoryBot.build(:scanned_map,
                     title: "test title",
                     coverage: [],
                     author: "test author",
                     creator: "test creator",
                     references: links.to_json,
                     subject: "test subject",
                     identifier: "ark:/99999/fk4",
                     holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/14",
                     imported_metadata: [{
                       coverage: imported_coverage
                     }])
  end
  let(:links) do
    {
      "http://www.jstor.org/stable/1797655": ["www.jstor.org"],
      "iiif_manifest_paths": "https://figgy.princeton.edu/concern/scanned_maps/pb8518582r/manifest"
    }
  end
  describe "Voyager downtime" do
    it "handles error caused by Voyager downtime" do
      stub_request(:get, "https://bibdata.princeton.edu/locations/digital_locations.json")
        .to_return(status: 502)
      expect(resource.decorate.rendered_holding_location).to eq([])
    end
  end
  describe "#iiif_manifest_attributes" do
    it "returns attributes" do
      expect(decorator.iiif_manifest_attributes).to include title: ["test title"]
      expect(decorator.iiif_manifest_attributes).to include author: ["test author"]
      expect(decorator.iiif_manifest_attributes).to include creator: ["test creator"]
      expect(decorator.iiif_manifest_attributes).to include subject: ["test subject"]
    end
  end
  it "exposes markup for rights statement" do
    expect(resource.decorate.rendered_rights_statement).not_to be_empty
    expect(resource.decorate.rendered_rights_statement.first).to match(/#{Regexp.escape(RightsStatements.no_known_copyright.to_s)}/)
  end
  it "exposes markup for rendered holding_location" do
    expect(resource.decorate.rendered_holding_location.first).to eq("Lewis Library")
  end
  it "exposes markup for rendered coverage" do
    expect(resource.decorate.rendered_coverage).to match(/#{Regexp.escape('Toggle Map')}/)
    expect(resource.decorate.rendered_coverage).to include(imported_coverage)
  end
  it "exposes markup for rendered links" do
    expect(resource.decorate.rendered_links).to include(/www.jstor.org/)
    expect(resource.decorate.rendered_links).not_to include(/manifest/)
  end
  it "renders the identifier as an ark" do
    expect(resource.decorate.ark).to eq("http://arks.princeton.edu/ark:/99999/fk4")
  end
  it "can attach folders" do
    expect(resource.decorate.attachable_objects).to include ScannedMap
  end
  it "can manage structure" do
    expect(decorator.manageable_structure?).to be true
  end
  describe "#decorated_raster_resources" do
    let(:raster_resource) { FactoryBot.create_for_repository(:raster_resource) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, member_ids: [raster_resource.id]) }
    it "accesses raster resources" do
      expect(resource.decorate.decorated_raster_resources).not_to be_empty
      expect(resource.decorate.decorated_raster_resources.first).to be_a RasterResourceDecorator
      expect(resource.decorate.decorated_raster_resources.first.id).to eq raster_resource.id
    end
  end
  describe "#display_imported_language" do
    context "with imported metadata" do
      let(:resource) do
        FactoryBot.build(:scanned_map,
                         title: "test title",
                         imported_metadata: [{
                           language: "eng"
                         }])
      end

      it "maps keys to english strings" do
        expect(decorator.display_imported_language).to eq ["English"]
      end
    end
  end
  describe "#language" do
    context "with direct metadata" do
      let(:resource) do
        FactoryBot.build(:scanned_map,
                         title: "test title",
                         language: ["eng"])
      end
      it "exposes the language" do
        expect(decorator.language).to eq ["English"]
      end
    end
  end
  context "with file sets" do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, member_ids: [file_set.id]) }
    it "retrieves members" do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end
  describe "#title" do
    context "with a portion note" do
      let(:resource) do
        FactoryBot.build(:scanned_map, title: "test title", portion_note: "sheet 1")
      end

      it "appends the portion note to the displayed title" do
        expect(resource.decorate.title).to eq ["test title (sheet 1)"]
      end
    end
  end
  describe "#collections" do
    let(:parent_collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, member_of_collection_ids: [parent_collection.id]) }

    before do
      parent_collection
    end

    it "retrieves all parent resources" do
      expect(decorator.collections.to_a).not_to be_empty
      expect(decorator.collections.first).to be_a Collection
      expect(decorator.collections.first.id).to eq parent_collection.id
    end
  end

  describe "#collection_slugs" do
    let(:parent_collection) { FactoryBot.create_for_repository(:collection) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, member_of_collection_ids: [parent_collection.id]) }

    before do
      parent_collection
    end

    it "retrieves collection slugs" do
      expect(decorator.collection_slugs).to contain_exactly parent_collection.slug.first
    end
  end

  describe "#decorated_file_sets" do
    it "retrieves all file sets" do
      expect(decorator.decorated_file_sets).to be_empty
    end
  end

  describe "#gbl_suppressed_override" do
    it "converts a bool to a string" do
      expect(decorator.gbl_suppressed_override).to eq "False"
    end
  end

  describe "#coverage" do
    let(:coverage) { "northlimit=10.0; eastlimit=15.0; southlimit=1.0; westlimit=5.0; units=degrees; projection=EPSG:4326" }

    context "with non-imported and imported coverage" do
      let(:resource) do
        FactoryBot.build(:scanned_map,
                        title: "test title",
                        coverage: coverage,
                        imported_metadata: [{
                          coverage: imported_coverage
                        }])
      end

      it "returns the non-imported coverage" do
        expect(decorator.coverage).to eq(coverage)
      end
    end

    context "with imported coverage" do
      let(:resource) do
        FactoryBot.build(:scanned_map,
                        title: "test title",
                        coverage: [],
                        imported_metadata: [{
                          coverage: imported_coverage
                        }])
      end

      it "returns the imported coverage" do
        expect(decorator.coverage).to eq(imported_coverage)
      end
    end

    context "with no non-imported or imported coverage" do
      let(:parent) do
        FactoryBot.create_for_repository(
          :map_set,
          title: "test title",
          coverage: [],
          imported_metadata: [{
            coverage: imported_coverage
          }]
        )
      end

      let(:resource) { parent.decorate.members.first }

      it "returns the coverage from the parent" do
        expect(decorator.coverage).to eq(imported_coverage)
      end
    end
  end
end
