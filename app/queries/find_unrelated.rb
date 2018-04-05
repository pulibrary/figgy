# frozen_string_literal: true
class FindUnrelated
  def self.queries
    [:find_unrelated]
  end

  attr_reader :query_service
  delegate :connection, to: :query_service
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # @param id [Valkyrie::ID, String]
  # @param model [Class, String]
  def find_unrelated(resource:, model:)
    run(model, [resource.id] + resource.member_ids)
  end

  private

    # The query for Solr
    # @param model [Valhalla::Resource] the model for the resources
    def query(model, ids)
      "#{Valkyrie::Persistence::Solr::Queries::MODEL}:#{model} AND -id:(#{ids.join(' ')})"
    end

    # Iterate through the results of the query
    # @param model [Valhalla::Resource] the model for the resources
    # @yield [Valhalla::Resource] a resource missing a thumbnail ID
    def each(model, ids)
      docs = Valkyrie::Persistence::Solr::Queries::DefaultPaginator.new
      while docs.has_next?
        docs = connection.paginate(docs.next_page, docs.per_page, "select", params: { q: query(model, ids) })["response"]["docs"]
        docs.each do |doc|
          yield resource_factory.to_resource(object: doc)
        end
      end
    end

    # Execute the query
    # @param model [Valhalla::Resource] the model for the resources
    def run(model, ids)
      enum_for(:each, model, ids)
    end
end
