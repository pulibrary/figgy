# frozen_string_literal: true
class Types::ScannedResourceType < Types::BaseObject
  implements Types::Resource
  def viewing_hint
    Array.wrap(super).first
  end

  def label
    Array.wrap(object.title).first
  end
end
