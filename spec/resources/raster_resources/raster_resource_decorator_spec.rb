# frozen_string_literal: true
require "rails_helper"

RSpec.describe RasterResourceDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:coverage) { "northlimit=07.033333; eastlimit=011.583333; southlimit=03.917778; westlimit=008.497222; units=degrees; projection=EPSG:4326" }
  let(:imported_coverage) { "northlimit=-00.500000; eastlimit=040.841667; southlimit=-12.000000; westlimit=028.666667; units=degrees; projection=EPSG:4326" }
  let(:resource) do
    FactoryBot.build(:raster_resource,
                     title: "test title",
                     author: "test author",
                     creator: "test creator",
                     coverage: coverage,
                     subject: "test subject",
                     identifier: "ark:/99999/fk4",
                     holding_location: "https://bibdata.princeton.edu/locations/delivery_locations/14",
                     imported_metadata: [{
                       coverage: imported_coverage
                     }])
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
    expect(resource.decorate.rendered_coverage).to include(coverage)
    expect(resource.decorate.rendered_coverage).not_to include(imported_coverage)
  end
  it "renders the identifier as an ark" do
    expect(resource.decorate.ark).to eq("http://arks.princeton.edu/ark:/99999/fk4")
  end
  it "can attach child members" do
    expect(resource.decorate.attachable_objects).to include RasterResource
  end
  it "cannot manage structure" do
    expect(decorator.manageable_structure?).to be false
  end
  describe "#vector_resource_members" do
    let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource) }
    let(:resource) { FactoryBot.create_for_repository(:raster_resource, member_ids: [vector_resource.id]) }
    it "accesses vector resources" do
      expect(resource.decorate.vector_resource_members).not_to be_empty
      expect(resource.decorate.vector_resource_members.first).to be_a VectorResourceDecorator
      expect(resource.decorate.vector_resource_members.first.id).to eq vector_resource.id
    end
  end
  describe "#decorated_scanned_map_parents" do
    let(:resource) { FactoryBot.create_for_repository(:raster_resource) }
    it "accesses parent scanned maps" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map, member_ids: [resource.id])
      expect(resource.decorate.decorated_scanned_map_parents).not_to be_empty
      expect(resource.decorate.decorated_scanned_map_parents.first).to be_a ScannedMapDecorator
      expect(resource.decorate.decorated_scanned_map_parents.first.id).to eq scanned_map.id
    end
  end
  describe "#display_imported_language" do
    context "with imported metadata" do
      let(:resource) do
        FactoryBot.build(:raster_resource,
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
        FactoryBot.build(:raster_resource,
                         title: "test title",
                         language: ["eng"])
      end
      it "exposes the language" do
        expect(decorator.language).to eq ["English"]
      end
    end
  end
  describe "#imported_attributes" do
    context "with imported metadata" do
      let(:resource) do
        FactoryBot.build(:scanned_map,
                         title: "test title",
                         imported_metadata: [{
                           subject: "test subject"
                         }])
      end

      it "maps keys to english strings" do
        expect(decorator.imported_attributes).to include subject: ["test subject"]
      end
    end
  end
  context "with file sets" do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set.id]) }
    it "retrieves members" do
      expect(resource.decorate.members.to_a).not_to be_empty
      expect(resource.decorate.members.to_a.first).to be_a FileSet
    end
  end

  describe "#raster_resource_members" do
    let(:child) { FactoryBot.create_for_repository(:raster_resource) }
    let(:resource) { FactoryBot.create_for_repository(:raster_resource, member_ids: [child.id]) }

    it "decorates member raster resources" do
      expect(resource.decorate.raster_resource_members).not_to be_empty
      expect(resource.decorate.raster_resource_members.first.id).to eq child.id
    end
  end
  describe "#title" do
    context "with a portion note" do
      let(:resource) do
        FactoryBot.build(:raster_resource, title: "test title", portion_note: "sheet 1")
      end

      it "appends the portion note to the displayed title" do
        expect(resource.decorate.title).to eq ["test title (sheet 1)"]
      end
    end
  end
  describe "#file_sets" do
    it "retrieves all file sets" do
      expect(decorator.file_sets).to be_empty
    end
  end
end
