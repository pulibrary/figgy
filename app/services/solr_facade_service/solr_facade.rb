# frozen_string_literal: true
class SolrFacadeService
  class SolrFacade
    delegate :total_pages, to: :query_response
    def initialize(repository:, query:, current_page:, per_page:)
      @repository = repository
      @query = query
      @current_page = current_page
      @per_page = per_page
    end

    def query_response
      @query_response ||= @repository.search(@query)
    end

    def members
      query_response.documents
    end
  end
end
