# frozen_string_literal: true
class Preserver::BinaryNodeComposite
  include Enumerable
  attr_reader :resource, :preservation_object
  delegate :each, to: :binary_intermediary_nodes
  def initialize(resource:, preservation_object:)
    @resource = resource
    @preservation_object = preservation_object
  end

  def binary_intermediary_nodes
    (resource.try(:preservation_targets) || []).map { |x| ::Preserver::BinaryIntermediaryNode.new(file_metadata: x, preservation_object: preservation_object) }
  end
end
