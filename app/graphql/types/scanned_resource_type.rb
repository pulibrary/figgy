# frozen_string_literal: true
class Types::ScannedResourceType < Types::BaseObject
  implements Types::Resource

  field :start_page, String, null: true

  def viewing_hint
    Array.wrap(super).first
  end

  def label
    Array.wrap(object.title).first
  end

  def start_page
    Array.wrap(object.start_canvas).first
  end
end
