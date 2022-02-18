# frozen_string_literal: true

class FacetItem
  attr_reader :value, :hits
  def initialize(value:, hits:)
    @value = value
    @hits = hits
  end
end
