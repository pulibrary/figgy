# frozen_string_literal: true

class Types::PlaylistType < Types::BaseObject
  implements Types::Resource

  field :manifest_url, String, null: true

  def source_metadata_identifier
  end

  def viewing_hint
  end

  def label
    Array.wrap(object.decorate.title).first
  end
end
