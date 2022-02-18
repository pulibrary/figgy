# frozen_string_literal: true

class Types::Thumbnail < Types::BaseObject
  field :id, String, null: true
  field :iiif_service_url, String, null: true
  field :thumbnail_url, String, null: true
end
