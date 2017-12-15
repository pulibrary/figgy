# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FacetIndexer do
  describe ".to_solr" do
    context "when the resource has imported metadata" do
      it "indexes relevant facets" do
        stub_bibdata(bib_id: "123456")
        scanned_resource = FactoryBot.create(:pending_scanned_resource, source_metadata_identifier: "123456", import_metadata: true)
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
        expect(output[:display_language_ssim]).to eq ["English"]
      end
    end
    context "when the resource has only local metadata" do
      let(:vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: 'Large vocabulary') }
      let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: 'Egg Creatures', member_of_vocabulary_id: [vocabulary.id]) }
      let(:language) { FactoryBot.create_for_repository(:ephemera_term, label: 'English', member_of_vocabulary_id: [vocabulary.id]) }
      let(:subject_terms) do
        [FactoryBot.create_for_repository(:ephemera_term, label: 'Birdo', member_of_vocabulary_id: [category.id]),
         FactoryBot.create_for_repository(:ephemera_term, label: 'Yoshi', member_of_vocabulary_id: [category.id])]
      end
      it "indexes subject, language" do
        folder = FactoryBot.create_for_repository(:ephemera_folder, subject: subject_terms, language: language)
        output = described_class.new(resource: folder).to_solr

        expect(output[:display_subject_ssim]).to contain_exactly("Birdo", "Yoshi", "Egg Creatures")
        expect(output[:display_language_ssim]).to contain_exactly("English")
      end
    end
  end
end
