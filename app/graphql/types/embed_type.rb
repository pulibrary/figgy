# frozen_string_literal: true
class Types::EmbedType < Types::BaseObject
  field :type, String, null: true
  field :content, String, null: true
  field :status, String, null: true
  field :media_type, String, null: true
end
