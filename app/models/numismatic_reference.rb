# frozen_string_literal: true
class NumismaticReference < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array

  attribute :author
  attribute :part_of_parent
  attribute :pub_info
  attribute :short_title
  attribute :title
  attribute :year
end
