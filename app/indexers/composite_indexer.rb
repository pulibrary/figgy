# frozen_string_literal: true

class CompositeIndexer
  attr_reader :indexers
  def initialize(*indexers)
    @indexers = indexers
  end

  def new(resource:)
    Instance.new(indexers, resource: resource)
  end

  class Instance
    attr_reader :indexers, :resource
    def initialize(indexers, resource:)
      @resource = resource
      @indexers = indexers.map { |i| i.new(resource: resource) }
    end

    def to_solr
      indexers.map(&:to_solr).inject({}, &:merge)
    end
  end
end
