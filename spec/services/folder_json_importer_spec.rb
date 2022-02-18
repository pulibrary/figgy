# frozen_string_literal: true

require "rails_helper"

RSpec.describe FolderJSONImporter do
  subject(:importer) { described_class.new(file: file, attributes: attributes, change_set_persister: change_set_persister) }
  let(:change_set_persister) do
    ChangeSetPersister.new(
      metadata_adapter: adapter,
      storage_adapter: Valkyrie::StorageAdapter.find(:disk_via_copy)
    )
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
  let(:file) { File.open(Rails.root.join("spec", "fixtures", "importable_json.json"), "r") }
  let(:project) { FactoryBot.create_for_repository(:ephemera_project) }
  let(:attributes) do
    {
      append_id: project.id
    }
  end
  describe "#import!" do
    it "imports a folder" do
      output = importer.import!
      first_resource = output.first
      expect(first_resource).to be_persisted
      expect(first_resource.title).to eq ["¿Y si defendemos la salud pública?"]
      expect(first_resource.sort_title).to eq ["y si defendemos la salud pública"]
      expect(first_resource.local_identifier).to eq ["pudl0025/02/0002"]
      expect(first_resource.identifier).to eq ["ark:/88435/1n79h566m"]
      expect(first_resource.date_created).to be_blank
      expect(first_resource.width).to eq ["42"]
      expect(first_resource.height).to eq ["30"]
      expect(first_resource.creator).to eq ["Central de Trabajadores Argentinos"]
      expect(first_resource.language.first).to be_a Valkyrie::ID
      language = adapter.query_service.find_by(id: first_resource.language.first)
      expect(language.label).to eq ["Spanish"]

      expect(first_resource.geographic_origin.first).to be_a Valkyrie::ID
      geographic_origin = adapter.query_service.find_by(id: first_resource.geographic_origin.first)
      expect(geographic_origin.label).to eq ["Argentina"]
      expect(geographic_origin.member_of_vocabulary_id).not_to be_blank

      expect(first_resource.page_count).to eq ["1"]
      expect(first_resource.subject.length).to eq 5
      expect(first_resource.subject.map(&:class).uniq).to eq [Valkyrie::ID]
      subjects = query_service.find_references_by(resource: first_resource, property: :subject)
      expect(subjects.flat_map(&:label)).to contain_exactly(
        "Government policy",
        "Education and state",
        "Labor unions",
        "Protest movements",
        "Strikes and lockouts"
      )
      subject_category = query_service.find_by(id: subjects.first.member_of_vocabulary_id.first)
      expect(subject_category).to be_a EphemeraVocabulary
      expect(subject_category.member_of_vocabulary_id).not_to be_blank
      expect(first_resource.member_ids.length).to eq 1

      expect(query_service.find_all_of_model(model: EphemeraTerm).to_a.length).to eq 7

      # appends to parent
      expect(first_resource.decorate.parent).to be_a EphemeraProject
    end
  end
end
