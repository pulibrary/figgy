# frozen_string_literal: true
class BulkEditController < ApplicationController
  include Blacklight::Searchable
  include ::Hydra::Catalog
  before_action :load_collections, :load_removable_collections, only: [:resources_edit]
  delegate :search_builder, :repository, to: :search_service

  def resources_edit
    authorize! :create, ScannedResource
    (solr_response, _document_list) = search_service.search_results do |builder|
      builder.with(edit_params)
    end
    @resources_count = solr_response["response"]["numFound"]
  end

  def resources_update
    authorize! :create, ScannedResource
    batches.each do |ids|
      BulkUpdateJob.perform_later(ids: ids, email: current_user.email, args: args, time: Time.current.to_s, search_params: search_params)
    end
    resources_count = batches.map(&:count).reduce(:+)
    flash[:notice] = "#{resources_count} resources were queued for bulk update."
    redirect_to root_url
  end

  private

    # used by search state to access filter fields
    def blacklight_config
      @blacklight_config ||= CatalogController.new.blacklight_config
    end

    def edit_params
      params.permit(:q, f: {})
    end

    def search_params
      @search_params ||= params.permit(search_params: {})["search_params"]
    end

    def load_collections
      @collections = Valkyrie.config.metadata_adapter.query_service.find_all_of_model(model: Collection).map(&:decorate) || []
    end

    def load_removable_collections
      @removable_collections = @collections.reject { |c| c.title == edit_params["f"]["member_of_collection_titles_ssim"][0] }
    end

    # Prepare / execute the search and process into id arrays
    def batches
      @batches ||= begin
        builder = initial_builder
        [].tap do |arr|
          loop do
            (solr_response, document_list) = search_service.search_results do |_builder|
              builder # use the builder we made
            end

            arr << document_list.map(&:id)
            break if (builder.page * builder.rows) >= solr_response["response"]["numFound"]
            builder.start = builder.rows * builder.page
            builder.page += 1
          end
        end
      end
    end

    def initial_builder
      builder = search_builder.with(search_params)
      builder.rows = params["batch_size"] || 50
      builder
    end

    def args
      {}.tap do |hash|
        hash[:mark_complete] = (params["mark_complete"] == "1")

        BulkUpdateJob.supported_attributes.each do |key|
          hash[key] = params[key.to_s] if params[key.to_s].present?
        end

        case params["embargo_date_action"]
        when "date"
          hash[:embargo_date] = params["embargo_date_value"]
        when "clear"
          hash[:embargo_date] = ""
        end
      end
    end
end
