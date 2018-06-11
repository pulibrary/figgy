# frozen_string_literal: true
class Types::ScannedResourceType < Types::BaseObject
  field :label, String, null: true
  field :viewing_hint, String, null: true

  def viewing_hint
    Array.wrap(super).first
  end

  def label
    Array.wrap(object.title).first
  end
end
