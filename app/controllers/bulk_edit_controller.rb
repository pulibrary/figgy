# frozen_string_literal: true
class BulkEditController < ApplicationController
  include Blacklight::SearchHelper
  before_action :load_collections, only: [:resources_edit]

  def resources_edit
    (solr_response, _document_list) = search_results(q: params["q"], f: params["f"])
    @resources_count = solr_response["response"]["numFound"]
  end

  def resources_update
    args = {}.tap do |hash|
      hash[:mark_complete] = (params["mark_complete"] == "1")
      BulkUpdateJob.supported_attributes.each do |key|
        hash[key] = params[key.to_s] if params[key.to_s].present?
      end
    end
    batches.each do |ids|
      BulkUpdateJob.perform_later(ids: ids, email: current_user.email, args: args, time: Time.current.to_s, search_params: search_params)
    end
    resources_count = batches.map(&:count).reduce(:+)
    flash[:notice] = "#{resources_count} resources were queued for bulk update."
    redirect_to root_url
  end

  private

    def search_params
      params.permit(search_params: {})["search_params"]
    end

    def load_collections
      @collections = Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Collection).map(&:decorate) || []
    end

    # Prepare / execute the search and process into id arrays
    def batches
      @batches ||= begin
        builder = initial_builder
        [].tap do |arr|
          loop do
            response = repository.search(builder)
            arr << response.documents.map(&:id)
            break if (builder.page * builder.rows) >= response["response"]["numFound"]
            builder.start = builder.rows * builder.page
            builder.page += 1
          end
        end
      end
    end

    def initial_builder
      builder_params = { q: params["search_params"]["q"], f: params["search_params"]["f"] }
      builder = search_builder.with(builder_params)
      builder.rows = params["batch_size"] || 50
      builder
    end
end
