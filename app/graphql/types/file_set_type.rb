# frozen_string_literal: true
class Types::FileSetType < Types::BaseObject
  implements Types::Resource
  def viewing_hint
    object.viewing_hint.try(:first)
  end

  def label
    object.title.try(:first)
  end

  def thumbnail_resource
    object
  end

  delegate :ocr_content, to: :object
end
