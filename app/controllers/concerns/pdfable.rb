# frozen_string_literal: true
module Pdfable
  extend ActiveSupport::Concern
  included do
    def pdf
      change_set = ChangeSet.for(find_resource(params[:id]))
      authorize! :pdf, change_set.resource
      resource_id = change_set.resource.id.to_s
      return redirect_to_download(resource_id) if change_set.resource.decorate.pdf_file
      if Figgy.background_pdf_generating?
        @decorated_resource = change_set.resource.decorate
        GeneratePdfJob.perform_later(resource_id: resource_id)
        render :pdf, layout: "download"
      else
        GeneratePdfJob.perform_now(resource_id: resource_id)
        redirect_to_download(resource_id)
      end
    end

    def redirect_to_download(resource_id)
      pdf_file = query_service.find_by(id: resource_id).decorate.pdf_file
      redirect_path_args = { resource_id: change_set.id, id: pdf_file.id }
      redirect_path_args[:auth_token] = auth_token_param if auth_token_param
      redirect_to download_path(redirect_path_args)
    end
  end
end
