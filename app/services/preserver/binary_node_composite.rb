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
    [:original_files, :intermediate_files, :preservation_files].flat_map do |node_type|
      Array(resource.try(node_type)).map { |x| ::Preserver::BinaryIntermediaryNode.new(binary_node: x, preservation_object: preservation_object) }
    end
  end
end
