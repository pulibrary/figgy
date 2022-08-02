# frozen_string_literal: true
class ParallelTestIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless ENV["TEST_ENV_NUMBER"]
    {
      parallel_core_ssi: ENV["TEST_ENV_NUMBER"]
    }
  end
end
