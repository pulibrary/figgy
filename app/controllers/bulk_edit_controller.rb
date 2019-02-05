# frozen_string_literal: true
class BulkEditController < ApplicationController
  include Blacklight::SearchHelper

  def resources_edit
    (@solr_response, @document_list) = search_results(q: params["q"], f: params["f"])
  end

  def resources_update
    (_, document_list) = search_results(q: params["search_params"]["q"], f: params["search_params"]["f"])
    ids = document_list.map(&:id)
    args = {}.tap do |hash|
      hash[:mark_complete] = (params["mark_complete"] == "1")
    end
    ids.each_slice(50) do |batch|
      BulkUpdateJob.perform_later(batch, args)
    end
    redirect_to root_url
  end
end
