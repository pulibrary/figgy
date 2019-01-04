# frozen_string_literal: true
class NumismaticFind < Resource
  include Valkyrie::Resource::AccessControls

  attribute :place
  attribute :date
  attribute :find_number, Valkyrie::Types::Integer
  attribute :feature
  attribute :locus
  attribute :description

  def title
    ["Find: #{find_number}"]
  end
end
