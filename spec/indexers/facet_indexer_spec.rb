# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FacetIndexer do
  describe ".to_solr" do
    context "when the resource has imported metadata" do
      it "indexes relevant facets" do
        stub_bibdata(bib_id: "123456")
        scanned_resource = FactoryGirl.create(:pending_scanned_resource, source_metadata_identifier: "123456", import_metadata: true)
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
        expect(output[:display_language_ssim]).to eq ["English"]
      end
    end
    context "when the resource has only local metadata" do
      let(:vocabulary) { FactoryGirl.create(:ephemera_vocabulary, label: 'Egg Creatures') }
      let(:language) { FactoryGirl.create(:ephemera_term, label: 'English') }
      let(:subject_terms) do
        [FactoryGirl.create(:ephemera_term, label: 'Birdo', member_of_vocabulary_id: vocabulary.id),
         FactoryGirl.create(:ephemera_term, label: 'Yoshi', member_of_vocabulary_id: vocabulary.id)]
      end
      it "indexes subject, language" do
        folder = FactoryGirl.create(:ephemera_folder, subject: subject_terms, language: language)
        output = described_class.new(resource: folder).to_solr

        expect(output[:display_subject_ssim]).to contain_exactly("Birdo", "Yoshi")
        expect(output[:display_language_ssim]).to contain_exactly("English")
      end
    end
  end
end
