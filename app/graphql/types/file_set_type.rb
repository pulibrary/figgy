# frozen_string_literal: true
class Types::FileSetType < Types::BaseObject
  implements Types::Resource
  def viewing_hint
    super.try(:first)
  end

  def label
    object.title.try(:first)
  end
end
