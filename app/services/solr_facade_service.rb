# frozen_string_literal: true
class SolrFacadeService
  # Factory for building SolrFacade Objects
  def self.instance(repository:, query:, current_page: 1, per_page: 10)
    current_page = current_page.blank? ? 1 : current_page.to_i
    per_page = per_page.blank? ? 10 : per_page.to_i
    SolrFacade.new(
      repository: repository,
      query: query,
      current_page: current_page,
      per_page: per_page
    )
  end
end
