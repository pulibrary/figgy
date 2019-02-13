# frozen_string_literal: true
class BulkEditController < ApplicationController
  include Blacklight::SearchHelper

  def resources_edit
    (solr_response, _document_list) = search_results(q: params["q"], f: params["f"])
    @resources_count = solr_response["response"]["numFound"]
  end

  def resources_update
    batch_size = params["batch_size"] || 50
    args = {}.tap do |hash|
      hash[:mark_complete] = (params["mark_complete"] == "1")
    end
    builder_params = { q: params["search_params"]["q"], f: params["search_params"]["f"] }
    builder = search_builder.with(builder_params)
    builder.rows = batch_size
    spawn_update_jobs(builder, args)
    redirect_to root_url
  end

  private

    def spawn_update_jobs(builder, args)
      loop do
        response = repository.search(builder)
        ids = response.documents.map(&:id)
        BulkUpdateJob.perform_later(ids, args)
        break if (builder.page * builder.rows) >= response["response"]["numFound"]
        builder.page += 1
      end
    end
end