# frozen_string_literal: true

require "rails_helper"

RSpec.describe PosterIngesterJob do
  let(:file) { Rails.root.join("spec", "fixtures", "importable_json.json").to_s }
  let(:project) { FactoryBot.create_for_repository(:ephemera_project) }
  let(:project_label) { project.title.first }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  describe "#perform_now" do
    before do
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary, label: "LAE Genres")
      FactoryBot.create_for_repository(:ephemera_term, label: "Posters", member_of_vocabulary_id: vocabulary.id)
    end
    it "ingests the folders and adds them to the project" do
      described_class.perform_now(file, project_label)
      reloaded_project = metadata_adapter.query_service.find_by(id: project.id)
      expect(reloaded_project.member_ids.length).to eq 1
    end
  end
end
