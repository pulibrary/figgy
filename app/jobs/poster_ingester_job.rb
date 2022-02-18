# frozen_string_literal: true

class PosterIngesterJob < ApplicationJob
  def perform(file, project_label)
    file = File.open(file)

    project = find_project(label: project_label)
    poster_genre = metadata_adapter.query_service.custom_queries.find_ephemera_term_by_label(label: "Posters", parent_vocab_label: "LAE Genres")
    raise "Both given project and the 'Poster' genre must exist before running." unless project.present? && poster_genre.present?
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      importer = FolderJSONImporter.new(file: file, attributes: {append_id: project.id, genre: poster_genre.id}, change_set_persister: buffered_changeset_persister)
      importer.import!
    end
  end

  def find_project(label:)
    metadata_adapter.query_service.custom_queries.find_by_property(property: :title, value: label).first
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def storage_adapter
    Valkyrie::StorageAdapter.find(:disk_via_copy)
  end

  def change_set_persister
    @change_set_persister ||= ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter)
  end
end
