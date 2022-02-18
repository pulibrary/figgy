# frozen_string_literal: true

class WithProxyForObject < SimpleDelegator
  attr_reader :members
  def initialize(logical_order, members)
    @members = members
    super logical_order
  end

  def proxy_for_object
    @proxy_for_object ||= members.find { |x| x.id == proxy.first }
  end

  def unstructured_objects
    @unstructured_objects ||=
      begin
        unstructured_proxies = (members - all_nodes).map { |x| {proxy: x.id} }
        node_class.new(nodes: unstructured_proxies)
      end
  end

  def node_class
    @node_class ||= Factory.new(members)
  end

  def each_node(&block)
    return enum_for(:each_node) unless block
    nodes.each do |node|
      yield node.proxy_for_object if node.proxy_for_object
      node.send(:each_node, &block)
    end
  end

  def nodes
    @nodes ||= super.map do |node|
      node_class.new(node)
    end
  end

  private

    def all_nodes
      @all_nodes ||= enum_for(:each_node).to_a
    end

    class Factory
      attr_reader :members
      def initialize(members)
        @members = members
      end

      def new(order_hash = {})
        ::WithProxyForObject.new(
          StructureNode.new(order_hash),
          members
        )
      end
    end
end
