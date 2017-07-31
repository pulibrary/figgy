# frozen_string_literal: true
class CollectionDecorator < Valkyrie::ResourceDecorator
  def manageable_files?
    false
  end
end
