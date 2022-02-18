# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarcRecordEnhancer do
  describe ".for" do
    context "when the resource has a bibid" do
      let(:resource) do
        FactoryBot.create_for_repository(
          :scanned_resource,
          source_metadata_identifier: "8543429",
          rights_statement: RDF::URI("http://cicognara.org/microfiche_copyright")
        )
      end
      before do
        stub_bibdata(bib_id: "8543429")
        stub_bibdata(bib_id: "8543429", content_type: BibdataStubbing::CONTENT_TYPE_MARC_XML)
      end
      it "returns a MarcRecordEnhancer with a marc record" do
        service = described_class.for(resource)
        expect(service).to be_a described_class
        expect(service.marc).to be_a MARC::Record
        expect(service.resource.id.to_s).to eq resource.id.to_s
      end
    end

    context "when the resource has no source_metadata_identifier field" do
      it "returns nil" do
        resource = FactoryBot.create_for_repository(:ephemera_folder)
        expect(described_class.for(resource)).to be_nil
      end
    end

    context "when the resource has nil source_metadata_identifier" do
      it "returns nil" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        expect(described_class.for(resource)).to be_nil
      end
    end

    context "when the resource has a pulfa id" do
      it "returns nil" do
        stub_pulfa(pulfa_id: "RBD1_c13076")
        resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "RBD1_c13076")
        expect(described_class.for(resource)).to be_nil
      end
    end
  end

  describe "#enhance_cicognara" do
    let(:marc_record) do
      MARC::Record.new.tap do |r|
        r.append(ark_856)
        r.append(manifest_856)
      end
    end
    let(:enhancer) { described_class.new(marc: marc_record, resource: resource) }
    let(:ark_856) do
      MARC::DataField.new(
        "856", "4", "1",
        MARC::Subfield.new("u", "http://arks.princeton.edu/ark:/88435/jm214s442")
      )
    end
    let(:manifest_856) do
      MARC::DataField.new(
        "856", "4", "1",
        MARC::Subfield.new("u", manifest_url)
      )
    end
    let(:resource) do
      FactoryBot.create_for_repository(
        :scanned_resource,
        source_metadata_identifier: "8543429",
        identifier: "ark:/88435/jm214s442",
        local_identifier: "dcl:xjt"
      )
    end
    let(:manifest_url) { Rails.application.routes.url_helpers.polymorphic_url([:manifest, resource]) }
    let(:metadata_mock) { double }
    before do
      stub_bibdata(bib_id: "8543429")
      stub_bibdata(bib_id: "8543429", content_type: BibdataStubbing::CONTENT_TYPE_MARC_XML)
      allow(resource).to receive(:imported_metadata).and_return([metadata_mock])
      allow(metadata_mock).to receive(:references).and_return(["Cicognara, 3723"])
    end

    context "when the record has 856es for manifest and ark" do
      it "leaves them in the record" do
        urls = enhancer.enhance_cicognara.fields("856").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == "1" &&
            field.subfields.count { |subfield| subfield.code == "u" } == 1
        end
        expect(urls.count).to eq 2
        subfields_u = urls.flat_map(&:subfields).select { |s| s.code == "u" }
        expect(subfields_u.map(&:value)).to include(
          "http://arks.princeton.edu/ark:/88435/jm214s442",
          manifest_url
        )
        expect(urls.flat_map(&:subfields).select { |s| s.code == "q" }.map(&:value)).to eq(["JSON (IIIF Manifest)"])
      end
    end

    context "when the record has some other 856" do
      let(:marc_record) do
        MARC::Record.new.tap do |r|
          r.append(other_856)
        end
      end
      let(:other_856) do
        MARC::DataField.new(
          "856", "4", "1",
          MARC::Subfield.new("u", "http://example.com/some_other_thing")
        )
      end
      it "replaces it with the manifest and ark links" do
        urls = enhancer.enhance_cicognara.fields("856").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == "1" &&
            field.subfields.count { |subfield| subfield.code == "u" } == 1
        end
        expect(urls.count).to eq 3
        subfields_u = urls.flat_map(&:subfields).select { |s| s.code == "u" }
        expect(subfields_u.map(&:value)).to include(
          "http://example.com/some_other_thing",
          "http://arks.princeton.edu/ark:/88435/jm214s442",
          manifest_url
        )
      end
    end

    context "when the record didn't have any 856es" do
      let(:marc_record) { MARC::Record.new }
      it "adds the manifest and ark links" do
        urls = enhancer.enhance_cicognara.fields("856").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == "1" &&
            field.subfields.count { |subfield| subfield.code == "u" } == 1
        end
        expect(urls.count).to eq 2
        subfields_u = urls.flat_map(&:subfields).select { |s| s.code == "u" }
        expect(subfields_u.map(&:value)).to include(
          "http://arks.princeton.edu/ark:/88435/jm214s442",
          manifest_url
        )
      end
    end

    context "when the record had the dcl in an 024" do
      let(:marc_record) do
        MARC::Record.new.tap do |r|
          r.append(dcl_024)
        end
      end
      let(:dcl_024) do
        MARC::DataField.new(
          "024", "8", " ",
          MARC::Subfield.new("a", "dcl:xjt")
        )
      end
      it "leaves that 024" do
        std_ids = enhancer.enhance_cicognara.fields("024").select do |field|
          field.indicator1 == "8" &&
            field.indicator2 == " " &&
            field.subfields.count { |subfield| subfield.code == "a" } == 1
        end
        expect(std_ids.count).to eq 1
        subfield_a = std_ids.first.subfields.find { |s| s.code == "a" }
        expect(subfield_a.value).to eq "dcl:xjt"
      end
    end

    context "when the record had something other than dcl in 024 8_ $a" do
      let(:marc_record) do
        MARC::Record.new.tap do |r|
          r.append(other_024)
        end
      end
      let(:other_024) do
        MARC::DataField.new(
          "024", "8", " ",
          MARC::Subfield.new("a", "rando id")
        )
      end
      it "adds another 024 with our dcl #" do
        expect(enhancer.enhance_cicognara.fields("024").count).to eq 2
        std_ids = enhancer.marc.fields("024").select do |field|
          field.indicator1 == "8" &&
            field.indicator2 == " " &&
            field.subfields.count { |subfield| subfield.code == "a" } == 1
        end
        expect(std_ids.count).to eq 2
        id_values = std_ids.flat_map(&:subfields).select { |s| s.code == "a" }
        expect(id_values.map(&:value)).to contain_exactly("dcl:xjt", "rando id")
      end
    end

    context "when the record had no 024" do
      let(:marc_record) { MARC::Record.new }
      it "adds an 024 with our dcl #" do
        std_ids = enhancer.enhance_cicognara.fields("024").select do |field|
          field.indicator1 == "8" &&
            field.indicator2 == " " &&
            field.subfields.count { |subfield| subfield.code == "a" } == 1
        end
        expect(std_ids.count).to eq 1
        subfield_a = std_ids.first.subfields.find { |s| s.code == "a" }
        expect(subfield_a.value).to eq "dcl:xjt"
      end
    end

    context "when the record had the cico number in a 510" do
      let(:marc_record) do
        MARC::Record.new.tap do |r|
          r.append(cico_510)
          r.append(cico_024)
        end
      end
      let(:cico_024) do
        MARC::DataField.new(
          "024", "7", " ",
          MARC::Subfield.new("a", "3723"),
          MARC::Subfield.new("2", "cico")
        )
      end
      let(:cico_510) do
        MARC::DataField.new(
          "510", "4", " ",
          MARC::Subfield.new("a", "Cicognara,"),
          MARC::Subfield.new("c", "3723")
        )
      end
      it "leaves that 510" do
        references = enhancer.enhance_cicognara.fields("510").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == " " &&
            field.subfields.find { |subfield| subfield.code == "a" }.value.starts_with?("Cicognara") &&
            field.subfields.count { |subfield| subfield.code == "c" } == 1
        end
        expect(references.count).to eq 1
        subfield_c = references.first.subfields.find { |s| s.code == "c" }
        expect(subfield_c.value).to eq "3723"
      end
    end

    context "when the record has the cico number in a 024" do
      let(:marc_record) do
        MARC::Record.new.tap do |r|
          r.append(cico_024)
        end
      end
      let(:cico_024) do
        MARC::DataField.new(
          "024", "7", " ",
          MARC::Subfield.new("a", "3723"),
          MARC::Subfield.new("2", "cico")
        )
      end
      before do
        allow(metadata_mock).to receive(:references).and_return([])
      end
      it "creates a 510 out of it" do
        references = enhancer.enhance_cicognara.fields("510").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == " " &&
            field.subfields.find { |subfield| subfield.code == "a" }.value.starts_with?("Cicognara") &&
            field.subfields.count { |subfield| subfield.code == "c" } == 1
        end
        expect(references.count).to eq 1
        subfield_c = references.first.subfields.find { |s| s.code == "c" }
        expect(subfield_c.value).to eq "3723"
      end
    end

    context "when the record had some other 510" do
      let(:marc_record) do
        MARC::Record.new.tap do |r|
          r.append(other_510)
        end
      end
      let(:other_510) do
        MARC::DataField.new(
          "510", "4", " ",
          MARC::Subfield.new("a", "Another identifier"),
          MARC::Subfield.new("c", "1")
        )
      end
      it "adds a 510 with the cicognara number" do
        expect(enhancer.enhance_cicognara.fields("510").count).to eq 2
        references = enhancer.marc.fields("510").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == " " &&
            field.subfields.find { |subfield| subfield.code == "a" }.value.starts_with?("Cicognara")
        end
        expect(references.count).to eq 1
        subfield_c = references.first.subfields.find { |s| s.code == "c" }
        expect(subfield_c.value).to eq "3723"
      end
    end

    context "when the record had no 510" do
      let(:marc_record) { MARC::Record.new }
      it "adds a 510 with the cicognara number" do
        expect(enhancer.enhance_cicognara.fields("510").count).to eq 1
        references = enhancer.marc.fields("510").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == " " &&
            field.subfields.find { |subfield| subfield.code == "a" }.value.starts_with?("Cicognara")
        end
        subfield_c = references.first.subfields.find { |s| s.code == "c" }
        expect(subfield_c.value).to eq "3723"
      end
    end
  end

  context "when the record has a 510, but the cico number has a suffix" do
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
    end
    let(:resource) do
      r = FactoryBot.build(:scanned_resource, source_metadata_identifier: "2085282")
      change_set_persister.save(change_set: ScannedResourceChangeSet.new(r))
    end
    let(:marc_record) { MARC::Record.new }
    let(:enhancer) { described_class.new(marc: marc_record, resource: resource) }
    before do
      stub_bibdata(bib_id: "2085282")
      stub_bibdata(bib_id: "2085282", content_type: BibdataStubbing::CONTENT_TYPE_MARC_XML)
    end

    context "when the record had the cico number in a 510 but with a suffix" do
      it "replaces that 510" do
        references = enhancer.enhance_cicognara.fields("510").select do |field|
          field.indicator1 == "4" &&
            field.indicator2 == " " &&
            field.subfields.find { |subfield| subfield.code == "a" }.value.starts_with?("Cicognara,") &&
            field.subfields.count { |subfield| subfield.code == "c" } == 1
        end
        expect(references.count).to eq 1
        subfield_c = references.first.subfields.find { |s| s.code == "c" }
        expect(subfield_c.value).to eq "2196"
      end
    end
  end
end
