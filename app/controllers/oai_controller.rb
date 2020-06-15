# frozen_string_literal: true
class OaiController < ApplicationController
  def index
    provider = OAI::Figgy::Provider.new
    response = provider.process_request(oai_params.to_h)
    render body: response, content_type: "text/xml"
  end

  private

    def oai_params
      params.permit(:verb, :identifier, :metadataPrefix, :set, :from, :until, :resumptionToken)
    end
end
