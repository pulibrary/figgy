# frozen_string_literal: true
class Types::PlaylistType < Types::BaseObject
  implements Types::Resource

  field :title, String, null: true
  field :manifest_url, String, null: true

  def title
    Array.wrap(object.decorate.title).first
  end

  def source_metadata_identifier; end

  def viewing_hint; end
end
