# frozen_string_literal: true
class CollectionDecorator < Valkyrie::ResourceDecorator
  def title
    Array(super).first
  end

  def manageable_files?
    false
  end

  # Nested collections are not currently supported
  def parents
    []
  end
  alias collections parents
end
