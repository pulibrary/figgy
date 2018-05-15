# frozen_string_literal: true
class MediaResourceDecorator < Valkyrie::ResourceDecorator
  display Schema::Common.attributes
  suppress :title,
           :thumbnail_id,
           :imported_author,
           :source_jsonld,
           :source_metadata,
           :sort_title

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  # TODO: Rename to decorated_file_sets
  def file_sets
    wayfinder.decorated_file_sets
  end
end
