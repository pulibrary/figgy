# frozen_string_literal: true
class SolrFacade
  delegate :total_pages, to: :query_response
  def initialize(repository:, query:, current_page: 1, per_page: 10)
    current_page = current_page.blank? ? 1 : current_page.to_i
    per_page = per_page.blank? ? 10 : per_page.to_i
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
