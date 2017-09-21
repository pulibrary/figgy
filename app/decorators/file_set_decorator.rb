# frozen_string_literal: true
class FileSetDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += [:height, :width, :mime_type, :size, :md5, :sha1, :sha256]

  def manageable_files?
    false
  end

  def parents
    query_service.find_parents(resource: self).to_a
  end

  def collections
    []
  end

  private

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end
    delegate :query_service, to: :metadata_adapter
end
