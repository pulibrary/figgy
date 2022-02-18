# frozen_string_literal: true

class Types::ScannedMapType < Types::BaseObject
  implements Types::Resource

  field :start_page, String, null: true
  field :viewing_direction, Types::ViewingDirectionEnum, null: true
  field :manifest_url, String, null: true
  field :source_metadata_identifier, String, null: true

  def viewing_hint
    Array.wrap(super).first
  end

  def viewing_direction
    Array.wrap(super).first
  end

  # Use decorated resource to include portion note in title
  def label
    Array.wrap(object.decorate.title).first
  end

  def start_page
    Array.wrap(object.start_canvas).first.to_s
  end

  def source_metadata_identifier
    Array.wrap(object.source_metadata_identifier).first
  end
end
