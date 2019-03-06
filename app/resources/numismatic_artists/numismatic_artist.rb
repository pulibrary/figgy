# frozen_string_literal: true
class NumismaticArtist < Resource
  include Valkyrie::Resource::AccessControls
  attribute :person
  attribute :signature
  attribute :role
  attribute :side
end
