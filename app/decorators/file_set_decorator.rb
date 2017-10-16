# frozen_string_literal: true
class FileSetDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += [:height, :width, :mime_type, :size, :md5, :sha1, :sha256]

  def manageable_files?
    false
  end

  def parents
    query_service.find_parents(resource: model).to_a.map(&:decorate)
  end

  def parent
    parents.first
  end

  def collections
    []
  end

  def collection_slugs
    @collection_slugs ||= parent.try(:collection_slugs)
  end
end
