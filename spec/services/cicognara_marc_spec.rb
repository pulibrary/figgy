# frozen_string_literal: true

require "rails_helper"

RSpec.describe CicognaraMarc do
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:out_dir) { Rails.root.join("tmp", "test", "marc_output") }
  let(:exporter) { described_class.new(cico_collection_id: collection.id, out_dir: out_dir) }

  describe "defaults" do
    let(:exporter) { described_class.new(cico_collection_id: collection.id) }
    it "initialized out_dir to tmp/cicognara_marc_output" do
      expect(exporter.out_dir).to eq Rails.root.join("tmp", "cicognara_marc_output")
    end
  end

  describe "#run" do
    context "when both records have different source metadata ids" do
      let(:enhancer1) { instance_double MarcRecordEnhancer }
      let(:enhancer2) { instance_double MarcRecordEnhancer }
      let(:minimal_record1) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "8543429")) } }
      let(:minimal_record2) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "4609321")) } }
      let(:writer) { double }

      before do
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "4609321")
        r1 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429")
        r2 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "4609321")
        allow(MarcRecordEnhancer).to receive(:for).with(r1).and_return(enhancer1)
        allow(MarcRecordEnhancer).to receive(:for).with(r2).and_return(enhancer2)
        allow(enhancer1).to receive(:enhance_cicognara).and_return(minimal_record1)
        allow(enhancer2).to receive(:enhance_cicognara).and_return(minimal_record2)
        allow(MARC::XMLWriter).to receive(:new).and_return(writer)
        allow(writer).to receive(:write)
        allow(writer).to receive(:close)
      end

      it "puts a marc file per bibid in a specified directory" do
        exporter.run
        expect(writer).to have_received(:write).twice
      end
    end

    context "when one record did not have a source metadata id" do
      let(:writer) { double }
      before do
        stub_bibdata(bib_id: "8543429")
        FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id)
        FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429")
        allow(MARC::XMLWriter).to receive(:new).and_return(writer)
        allow(writer).to receive(:write)
        allow(writer).to receive(:close)
        stub_bibdata(bib_id: "8543429", content_type: BibdataStubbing::CONTENT_TYPE_MARC_XML)
      end

      it "doesn't error and doesn't write that record" do
        exporter.run
        expect(writer).to have_received(:write).once
      end
    end

    context "when two records have the same source metadata id" do
      let(:enhancer) { instance_double MarcRecordEnhancer }
      let(:minimal_record) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "8543429")) } }
      let(:writer) { double }

      before do
        stub_bibdata(bib_id: "8543429")
        r1 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429")
        r2 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429")
        allow(MarcRecordEnhancer).to receive(:for).with(r1).and_return(enhancer)
        allow(MarcRecordEnhancer).to receive(:for).with(r2).and_return(enhancer)
        allow(enhancer).to receive(:enhance_cicognara).and_return(minimal_record)
        allow(MARC::XMLWriter).to receive(:new).and_return(writer)
        allow(writer).to receive(:write)
        allow(writer).to receive(:close)
      end

      it "writes just one marc record" do
        exporter.run
        expect(writer).to have_received(:write).once
      end
    end

    context "when one of the records is not public-visible" do
      let(:enhancer1) { instance_double MarcRecordEnhancer }
      let(:enhancer2) { instance_double MarcRecordEnhancer }
      let(:minimal_record1) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "8543429")) } }
      let(:minimal_record2) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "4609321")) } }
      let(:writer) { double }

      before do
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "4609321")
        r1 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429")
        r2 = FactoryBot.create_for_repository(:complete_private_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "4609321")
        allow(MarcRecordEnhancer).to receive(:for).with(r1).and_return(enhancer1)
        allow(MarcRecordEnhancer).to receive(:for).with(r2).and_return(enhancer2)
        allow(enhancer1).to receive(:enhance_cicognara).and_return(minimal_record1)
        allow(enhancer2).to receive(:enhance_cicognara).and_return(minimal_record2)
        allow(MARC::XMLWriter).to receive(:new).and_return(writer)
        allow(writer).to receive(:write)
        allow(writer).to receive(:close)
      end

      it "writes just one marc record" do
        exporter.run
        expect(writer).to have_received(:write).once
      end
    end

    context "when one of the records is not in a complete state" do
      let(:enhancer1) { instance_double MarcRecordEnhancer }
      let(:enhancer2) { instance_double MarcRecordEnhancer }
      let(:minimal_record1) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "8543429")) } }
      let(:minimal_record2) { MARC::Record.new.tap { |record| record.append(MARC::ControlField.new("001", "4609321")) } }
      let(:writer) { double }

      before do
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "4609321")
        r1 = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "8543429")
        r2 = FactoryBot.create_for_repository(:pending_scanned_resource, member_of_collection_ids: collection.id, source_metadata_identifier: "4609321")
        allow(MarcRecordEnhancer).to receive(:for).with(r1).and_return(enhancer1)
        allow(MarcRecordEnhancer).to receive(:for).with(r2).and_return(enhancer2)
        allow(enhancer1).to receive(:enhance_cicognara).and_return(minimal_record1)
        allow(enhancer2).to receive(:enhance_cicognara).and_return(minimal_record2)
        allow(MARC::XMLWriter).to receive(:new).and_return(writer)
        allow(writer).to receive(:write)
        allow(writer).to receive(:close)
      end

      it "writes just one marc record" do
        exporter.run
        expect(writer).to have_received(:write).once
      end
    end
  end

  describe "#retrieve_ehanced_marc" do
    context "when passed an array of size 1" do
      let(:resource) do
        FactoryBot.create_for_repository(
          :scanned_resource
        )
      end
      let(:enhancer) { instance_double MarcRecordEnhancer }
      before do
        allow(MarcRecordEnhancer).to receive(:for).with(resource).and_return(enhancer)
        allow(enhancer).to receive(:enhance_cicognara).and_return(MARC::Record.new)
      end
      it "returns the marc for that record" do
        marc_record = exporter.retrieve_ehanced_marc([resource])
        expect(marc_record).to be_a MARC::Record
      end
    end

    context "when passed multiple resources" do
      let(:resource1) do
        FactoryBot.create_for_repository(
          :scanned_resource,
          source_metadata_identifier: "8543429",
          identifier: "ark:/88435/#{blade1}",
          local_identifier: li1
        )
      end
      let(:resource2) do
        FactoryBot.create_for_repository(
          :scanned_resource,
          source_metadata_identifier: "8543429",
          identifier: "ark:/88435/#{blade2}",
          local_identifier: li2
        )
      end

      let(:ark_856_1) do
        MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", "http://arks.princeton.edu/ark:/88435/#{blade1}"))
      end
      let(:ark_856_2) do
        MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", "http://arks.princeton.edu/ark:/88435/#{blade2}"))
      end
      let(:manifest_856_1) do
        f = MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", manifest_url_1))
        f.append(MARC::Subfield.new("q", "JSON (IIIF Manifest)"))
        f
      end
      let(:manifest_856_2) do
        f = MARC::DataField.new("856", "4", "1", MARC::Subfield.new("u", manifest_url_2))
        f.append(MARC::Subfield.new("q", "JSON (IIIF Manifest)"))
        f
      end
      let(:manifest_url_1) { Rails.application.routes.url_helpers.polymorphic_url([:manifest, resource1]) }
      let(:manifest_url_2) { Rails.application.routes.url_helpers.polymorphic_url([:manifest, resource2]) }
      let(:metadata_mock) { double }
      let(:li1) { "dcl:li1" }
      let(:li2) { "dcl:li2" }
      let(:ref1) { "123" }
      let(:ref2) { "456" }
      let(:blade1) { "jm214s442" }
      let(:blade2) { "kn323t553" }

      before do
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "8543429", content_type: BibdataStubbing::CONTENT_TYPE_MARC_XML)
        allow(resource2).to receive(:imported_metadata).and_return([metadata_mock])
        allow(metadata_mock).to receive(:references).and_return(["Cicognara, 3724"])
      end

      it "returns a single marc record that contains all the relevant IDs" do
        marc_record = exporter.retrieve_ehanced_marc([resource1, resource2])
        expect(marc_record).to be_a MARC::Record
        # the record had 1 in addition to the 4 we want
        expect(marc_record.fields("856").count).to eq 5
        expect(marc_record.fields("856")).to include manifest_856_1, ark_856_1, manifest_856_2, ark_856_2
        # the record had both cico numbers and 2 other dcl numbers
        expect(marc_record.fields("024").count).to eq 6
        subfields_a = marc_record.fields("024").flat_map(&:subfields).select { |s| s.code == "a" }.map(&:value)
        expect(subfields_a).to include li1, li2
        # Note this example doesn't really reflect reality of the data:
        #   Figgy only pulls these numbers from the marc record to begin with,
        #   so enhancing them back in is sort of weird; but in the future we may
        #   need to because of this exact case: multiple objects needing to be
        #   correlated with their correct ID.
        expect(marc_record.fields("510").count).to eq 2
        subfields_c = marc_record.fields("510").flat_map(&:subfields).select { |s| s.code == "c" }.map(&:value)
        expect(subfields_c).to include "3723", "3724"
      end
    end
  end
end
