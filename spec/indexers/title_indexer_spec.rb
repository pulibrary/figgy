# frozen_string_literal: true

require "rails_helper"

RSpec.describe TitleIndexer do
  describe ".to_solr" do
    let(:title_with_subtitle) { TitleWithSubtitle.new(title: "Stanhope Hall", subtitle: "College Offices") }
    let(:string_title) { "Albert Einstein in Princeton" }
    let(:rdf_literal_title) { RDF::Literal.new("Wilson College", language: "eng") }
    let(:grouping) { Grouping.new(elements: ["A title", "A different but related title"]) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:change_set_persister) do
      ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter)
    end

    it "properly indexes all the title values" do
      resource = FactoryBot.build(:scanned_resource, title: [title_with_subtitle, string_title, rdf_literal_title, grouping])
      all_titles = ["Stanhope Hall: College Offices", string_title, "Wilson College", "A title; A different but related title"]

      output = described_class.new(resource: resource).to_solr
      expect(output[:figgy_title_tesim]).to contain_exactly(*all_titles)
      expect(output[:figgy_title_tesi]).to eq title_with_subtitle.to_s
      expect(output[:figgy_title_ssim]).to contain_exactly(*all_titles)
      expect(output[:figgy_title_ssi]).to eq title_with_subtitle.to_s
    end

    it "returns empty hash if there is not a title field" do
      resource = FileMetadata.new
      output = described_class.new(resource: resource).to_solr
      expect(output).to eq({})
    end

    it "returns empty hash if title is nil" do
      resource = FactoryBot.build(:scanned_resource, title: nil)
      output = described_class.new(resource: resource).to_solr
      expect(output).to eq({})
    end

    context "with a decorated title" do
      it "properly indexes the title values" do
        resource = FactoryBot.build(:numismatic_place)
        title = "city, state, region"

        output = described_class.new(resource: resource).to_solr
        expect(output[:figgy_title_tesim]).to contain_exactly(title)
        expect(output[:figgy_title_tesi]).to eq title
        expect(output[:figgy_title_ssim]).to contain_exactly(title)
        expect(output[:figgy_title_ssi]).to eq title
      end
    end
    context "with a distinct indexed title" do
      it "properly indexes the indexed title values" do
        resource = FactoryBot.build(:numismatic_reference, year: 2020)
        title = "short-title, Test Reference, 2020"

        output = described_class.new(resource: resource).to_solr
        expect(output[:figgy_title_tesim]).to contain_exactly(title)
        expect(output[:figgy_title_tesi]).to eq title
        expect(output[:figgy_title_ssim]).to contain_exactly(title)
        expect(output[:figgy_title_ssi]).to eq title
      end
    end
  end
end
