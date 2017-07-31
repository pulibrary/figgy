# frozen_string_literal: true
class CollectionDecorator < Valkyrie::ResourceDecorator
  def title
    Array(super).first
  end

  def manageable_files?
    false
  end
end
