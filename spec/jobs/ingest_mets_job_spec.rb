# frozen_string_literal: true
require 'rails_helper'

RSpec.describe IngestMETSJob do
  describe "integration test" do
    let(:user) { FactoryGirl.build(:admin) }
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4612596.mets") }
    let(:tiff_file) { Rails.root.join("spec", "fixtures", "files", "example.tif") }
    let(:mime_type) { 'image/tiff' }
    let(:file) { IoDecorator.new(File.new(tiff_file), mime_type, File.basename(tiff_file)) }
    let(:order) do
      {
        nodes: [{
          label: 'leaf 1', nodes: [{
            label: 'leaf 1. recto', proxy: fileset2.id
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
      stub_bibdata(bib_id: '4612596')
      stub_bibdata(bib_id: '4609321')
    end

    let(:adapter) { Valkyrie.config.metadata_adapter }
    it "ingests a METS file" do
      described_class.perform_now(mets_file, user)

      book = adapter.query_service.find_all_of_model(model: ScannedResource).first
      expect(book).not_to be_nil
      expect(book.source_metadata_identifier).to eq ["4612596"]
      expect(book.logical_structure[0].nodes.length).to eq 1
      expect(book.logical_structure[0].nodes[0].label).to contain_exactly 'leaf 1'
      expect(book.logical_structure[0].nodes[0].nodes[0].label).to contain_exactly 'leaf 1. recto'
      expect(book.member_ids).not_to be_blank
      file_sets = adapter.query_service.find_members(resource: book)
      expect(book.logical_structure[0].nodes[0].nodes[0].proxy).to eq [file_sets.first.id]
      expect(file_sets.first.title).to eq ["leaf 1. recto"]
    end
    context "when given a work with volumes" do
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4609321-s42.mets") }
      it "ingests it" do
        described_class.perform_now(mets_file, user)

        books = adapter.query_service.find_all_of_model(model: ScannedResource).to_a
        parent_book = books.find { |x| x.source_metadata_identifier.present? }
        child_books = adapter.query_service.find_members(resource: parent_book).to_a

        expect(parent_book.member_ids.length).to eq 2
        expect(child_books[0].logical_structure[0].label).to eq ["Main Structure"]
        expect(child_books[0].title).to eq ["first volume"]
        expect(child_books[1].title).to eq ["second volume"]
      end
    end
  end
end
