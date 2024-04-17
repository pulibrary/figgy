# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  context "when the resource has linked vocabulary terms" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: ephemera_folder.id)) }

    let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Art and Culture") }
    let(:subject_term) { FactoryBot.create_for_repository(:ephemera_term, label: "Architecture", member_of_vocabulary_id: category.id) }

    let(:genres_category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Library of Congress Genre/Form Terms") }
    let(:genre_term) { FactoryBot.create_for_repository(:ephemera_term, label: "Experimental films", member_of_vocabulary_id: genres_category.id) }
    let(:ephemera_folder) do
      FactoryBot.create_for_repository(:ephemera_folder, subject: [subject_term.id], genre: genre_term.id)
    end
    it "transforms the subject terms into JSON-LD" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output).to include "metadata"
      metadata = output["metadata"]
      expect(metadata).to be_kind_of Array
      expect(metadata.length).to eq(20)

      metadata_object = metadata.find { |h| h["label"] == "Subject" }
      metadata_values = metadata_object["value"]
      expect(metadata_values).to be_kind_of Array
      metadata_value = metadata_values.shift

      expect(metadata_value).to eq subject_term.label.first

      metadata_object = metadata.find { |h| h["label"] == "Genre" }
      metadata_values = metadata_object["value"]
      expect(metadata_values).to be_kind_of Array
      metadata_value = metadata_values.shift

      expect(metadata_value).to eq genre_term.label.first
    end
  end

  context "when an ephemera folder has a transliterated title" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: folder.id)) }
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder, title: ["title"], transliterated_title: ["transliterated"]) }
    it "includes that in the manifest label" do
      output = manifest_builder.build
      expect(output["label"]).to eq ["title", "transliterated"]
    end
  end

  context "when given an ephemera project" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: ephemera_project.id)) }
    let(:ephemera_project) do
      FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, ephemera_term.id, folder2.id])
    end
    let(:ephemera_term) { FactoryBot.create_for_repository(:ephemera_term) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id) }
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:folder2) { FactoryBot.create_for_repository(:ephemera_folder, member_ids: folder3.id) }
    let(:folder3) { FactoryBot.create_for_repository(:ephemera_folder) }
    let(:change_set) { EphemeraProjectChangeSet.new(ephemera_project) }
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["metadata"]).to be_kind_of Array
      expect(output["metadata"]).not_to be_empty
      expect(output["metadata"].first).to include "label" => "Exhibit", "value" => [ephemera_project.decorate.slug]
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/ephemera_folders/#{folder.id}/manifest"
      expect(output["manifests"][1]["@id"]).to eq "http://www.example.com/concern/ephemera_folders/#{folder2.id}/manifest"
      expect(output["manifests"].length).to eq 2
    end
  end
end
