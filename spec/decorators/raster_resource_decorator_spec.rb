# frozen_string_literal: true
require "rails_helper"

RSpec.describe RasterResourceDecorator do
  with_queue_adapter :inline

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

  before do
    allow(MosaicJob).to receive(:perform_later)
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
  describe "#file_sets" do
    let(:file_set) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:file_set)
      adapter.persister.save(resource: res)
    end
    let(:resource) { FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set.id]) }
    it "returns attached file sets" do
      expect(resource.decorate.file_sets.first).to eq file_set
    end
  end
  describe "#decorated_vector_resources" do
    let(:vector_resource) { FactoryBot.create_for_repository(:vector_resource) }
    let(:resource) { FactoryBot.create_for_repository(:raster_resource, member_ids: [vector_resource.id]) }
    it "accesses vector resources" do
      expect(resource.decorate.decorated_vector_resources).not_to be_empty
      expect(resource.decorate.decorated_vector_resources.first).to be_a VectorResourceDecorator
      expect(resource.decorate.decorated_vector_resources.first.id).to eq vector_resource.id
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

  describe "#decorated_raster_resources" do
    let(:child) { FactoryBot.create_for_repository(:raster_resource) }
    let(:resource) { FactoryBot.create_for_repository(:raster_resource, member_ids: [child.id]) }

    it "decorates member raster resources" do
      expect(resource.decorate.decorated_raster_resources).not_to be_empty
      expect(resource.decorate.decorated_raster_resources.first.id).to eq child.id
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
  describe "#decorated_file_sets" do
    it "retrieves all file sets" do
      expect(decorator.decorated_file_sets).to be_empty
    end
  end

  describe "#coverage" do
    context "with non-imported and imported coverage" do
      let(:resource) do
        FactoryBot.build(:raster_resource,
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
        FactoryBot.build(:raster_resource,
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
          :raster_set,
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

  context "with no non-imported or imported coverage and a raster file" do
    let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tif") }
    let(:tika_output) { tika_geotiff_output }
    let(:resource) do
      FactoryBot.create_for_repository(
        :raster_resource,
        files: [file],
        title: "test title",
        identifier: "ark:/99999/fk4",
        coverage: []
      )
    end
    let(:coverage) { "northlimit=9.01; eastlimit=11.21; southlimit=0; westlimit=0; units=degrees; projection=EPSG:4326" }

    it "returns coverage from the raster file" do
      expect(decorator.coverage).to eq(coverage)
    end
  end
end
