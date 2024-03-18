# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestMETSJob do
  with_queue_adapter :inline
  let(:adapter) { Valkyrie.config.metadata_adapter }
  let(:user) { FactoryBot.build(:admin) }
  let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-9946125963506421.mets") }
  let(:tiff_file) { Rails.root.join("spec", "fixtures", "files", "example.tif") }
  let(:mime_type) { "image/tiff" }
  let(:file) { IoDecorator.new(File.new(tiff_file), mime_type, File.basename(tiff_file)) }
  let(:order) do
    {
      nodes: [{
        label: "leaf 1", nodes: [{
          label: "leaf 1. recto", proxy: fileset2.id
        }]
      }]
    }
  end

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with("/tmp/pudl0001/4612596/00000001.tif").and_return(File.open(tiff_file))
    allow(File).to receive(:open).with("/users/escowles/downloads/tmp/00000001.tif").and_return(File.open(tiff_file))
    allow(File).to receive(:open).with("/users/escowles/downloads/tmp/00000002.tif").and_return(File.open(tiff_file))
    allow(File).to receive(:open).with("/users/escowles/downloads/tmp/00000003.tif").and_return(File.open(tiff_file))
    allow(File).to receive(:open).with("/users/escowles/downloads/tmp/00000657.tif").and_return(File.open(tiff_file))
    allow(File).to receive(:open).with("/users/escowles/downloads/tmp/00000658.tif").and_return(File.open(tiff_file))
    allow(File).to receive(:open).with("/users/escowles/downloads/tmp/00000659.tif").and_return(File.open(tiff_file))
    # this is doing something in a characterization / derivative job
    #   it looks like this could also be achieved by having :copy_before_ingest return false
    #   if something more general is needed
    allow_any_instance_of(IngestableFile).to receive(:path).and_return(tiff_file)
    stub_catalog(bib_id: "9946125963506421")
    stub_catalog(bib_id: "9946093213506421")
  end

  context "when ingesting to an existing collection" do
    let(:pudl0001) { FactoryBot.create_for_repository(:collection, slug: "pudl0001") }
    it "ingests a METS file" do
      pudl0001
      described_class.perform_now(mets_file, user)
      allow(FileUtils).to receive(:mv).and_call_original

      book = adapter.query_service.find_all_of_model(model: ScannedResource).first
      expect(book).not_to be_nil
      expect(book.source_metadata_identifier).to eq ["9946125963506421"]
      expect(book.identifier.first).to eq "ark:/88435/5m60qr98h"
      expect(book.logical_structure[0].nodes.length).to eq 1
      expect(book.logical_structure[0].nodes[0].label).to contain_exactly "leaf 1"
      expect(book.logical_structure[0].nodes[0].nodes[0].label).to contain_exactly "leaf 1. recto"
      expect(book.member_ids).not_to be_blank
      file_sets = adapter.query_service.find_members(resource: book)
      expect(book.logical_structure[0].nodes[0].nodes[0].proxy).to eq [file_sets.first.id]
      expect(file_sets.first.title).to eq ["leaf 1. recto"]
      expect(file_sets.first.derivative_file).not_to be_blank
      expect(FileUtils).not_to have_received(:mv)
      expect(book.member_of_collection_ids).to eq [pudl0001.id]
      expect(file_sets.map(&:title).to_a).to include ["pudl0001-9946125963506421.mets"]
      expect(file_sets.map(&:mime_type).to_a).to include ["application/xml; schema=mets"]
    end
  end

  context "when extracting metadata from the MODS Document" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "tsop_typed_no_files.mets") }

    it "ingests the METS file and extracts MODS metadata" do
      FactoryBot.create_for_repository(:collection, slug: "pudl0044")
      described_class.perform_now(mets_file, user, true)
      allow(FileUtils).to receive(:mv).and_call_original

      book = adapter.query_service.find_all_of_model(model: ScannedResource).first
      expect(book).not_to be_nil
      expect(book.title).to include "This side of paradise"
      expect(book.change_set).to eq "simple"
    end

    describe "rights statement" do
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }

      it "defaults to copyright not evaluated" do
        stub_ezid(shoulder: "88435", blade: "ww72bb49w", location: "http://findingaids.princeton.edu/collections/AC111")
        FactoryBot.create_for_repository(:collection, slug: "pudl0038")
        described_class.perform_now(mets_file, user, true)

        book = adapter.query_service.find_all_of_model(model: ScannedResource).first
        expect(book.rights_statement).to contain_exactly RightsStatements.copyright_not_evaluated.to_s
      end
    end

    describe "locations" do
      before do
        stub_ezid(shoulder: "88435", blade: "ww72bb49w", location: "http://findingaids.princeton.edu/collections/AC111")
      end
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }

      it "maps holding_simple_sublocation to controlled vocab term for holding_location" do
        FactoryBot.create_for_repository(:collection, slug: "pudl0038")
        described_class.perform_now(mets_file, user, true)

        book = adapter.query_service.find_all_of_model(model: ScannedResource).first
        expect(book.holding_location).to contain_exactly("https://bibdata.princeton.edu/locations/delivery_locations/9")
      end

      it "pulls shelf_locator into location attribute" do
        FactoryBot.create_for_repository(:collection, slug: "pudl0038")
        described_class.perform_now(mets_file, user, true)

        book = adapter.query_service.find_all_of_model(model: ScannedResource).first
        expect(book.location).to contain_exactly("Mudd, Box AD01, Item 7350")
      end

      it "puts collection_code into archival_collection_code" do
        FactoryBot.create_for_repository(:collection, slug: "pudl0038")
        described_class.perform_now(mets_file, user, true)

        book = adapter.query_service.find_all_of_model(model: ScannedResource).first
        expect(book.archival_collection_code).to eq "AC111"
      end
    end
  end

  context "When there wasn't collection yet" do
    it "raises a CollectionNotFoundError" do
      expect { described_class.perform_now(mets_file, user) }.to raise_error IngestMETSJob::CollectionNotFoundError
    end
  end

  context "when given a work with volumes" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-9946093213506421-s42.mets") }
    it "ingests it" do
      described_class.perform_now(mets_file, user)

      books = adapter.query_service.find_all_of_model(model: ScannedResource).to_a
      parent_book = books.find { |x| x.source_metadata_identifier.present? }
      child_books = adapter.query_service.find_members(resource: parent_book).to_a

      expect(parent_book.member_ids.length).to eq 3
      expect(child_books[0].logical_structure[0].label).to eq ["Main Structure"]
      expect(child_books[0].title).to eq ["first volume"]
      expect(child_books[1].title).to eq ["second volume"]
      file_sets = adapter.query_service.find_members(resource: child_books[0])
      expect(file_sets.map(&:title)).not_to include "pudl0001-9946093213506421-s42.mets"
      file_sets = adapter.query_service.find_members(resource: child_books[1])
      expect(file_sets.map(&:title)).not_to include "pudl0001-9946093213506421-s42.mets"
    end
  end

  context "when extracting metadata from the MODS Document for a work with volumes" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "tsop_typed_mvw_no_files.mets") }

    it "ingests the METS file with child volumes and extracts MODS metadata" do
      described_class.perform_now(mets_file, user, true)
      allow(FileUtils).to receive(:mv).and_call_original

      books = adapter.query_service.find_all_of_model(model: ScannedResource).to_a
      parent_book = books.sort_by(&:created_at).last
      child_books = adapter.query_service.find_members(resource: parent_book).to_a

      expect(parent_book.member_ids.length).to eq 3
      expect(child_books[0].logical_structure[0].label).to eq ["Main Structure"]
      expect(child_books[0].title).to eq ["first volume"]
      expect(child_books[1].title).to eq ["second volume"]
    end
  end

  context "when given a work with volumes" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-9946093213506421-s42.mets") }
    it "ingests it" do
      described_class.perform_now(mets_file, user)

      books = adapter.query_service.find_all_of_model(model: ScannedResource).to_a
      parent_book = books.find { |x| x.source_metadata_identifier.present? }
      child_books = adapter.query_service.find_members(resource: parent_book).to_a

      expect(parent_book.member_ids.length).to eq 3
      expect(child_books[0].logical_structure[0].label).to eq ["Main Structure"]
      expect(child_books[0].title).to eq ["first volume"]
      expect(child_books[1].title).to eq ["second volume"]
    end
  end

  context "when given a pudl0003 MVW with no structmap" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0003-tc85_2621.mets") }
    before do
      allow(File).to receive(:open).with("/mnt/diglibdata/pudl/pudl0003/tc85_2621/vol01/00000001.tif").and_return(File.open(tiff_file))
      allow(File).to receive(:open).with("/mnt/diglibdata/pudl/pudl0003/tc85_2621/vol01/00000002.tif").and_return(File.open(tiff_file))
      allow(File).to receive(:open).with("/mnt/diglibdata/pudl/pudl0003/tc85_2621/vol02/00000001.tif").and_return(File.open(tiff_file))
    end
    it "hacks together a MVW from the path" do
      described_class.perform_now(mets_file, user)

      books = adapter.query_service.find_all_of_model(model: ScannedResource)
      parent_book = books.find { |x| x.source_metadata_identifier.present? }
      expect(parent_book).not_to be_nil
      expect(parent_book.member_ids).not_to be_blank
      children = adapter.query_service.find_members(resource: parent_book).to_a

      expect(children.map(&:class)).to eq [ScannedResource, ScannedResource, FileSet]
      expect(children[0].member_ids.length).to eq 2
      expect(children[1].member_ids.length).to eq 1
    end
  end
end
