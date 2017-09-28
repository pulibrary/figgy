# frozen_string_literal: true
class FileSetDecorator < Valkyrie::ResourceDecorator
  delegate :query_service, to: :metadata_adapter
  self.display_attributes += [:height, :width, :mime_type, :size, :md5, :sha1, :sha256]

  def manageable_files?
    false
  end

  def parent
    query_service.find_parents(resource: model).try(:first)
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end

  def collections
    []
  end
end
