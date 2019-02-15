# frozen_string_literal: true
module OrangelightDocumentController
  extend ActiveSupport::Concern

  included do
    def orangelight
      respond_to do |f|
        f.json do
          render json: orangelight_document
        end
      end
    end
  end

  private

    def orangelight_document
      @resource = find_resource(params[:id])
      @orangelight_document ||= OrangelightDocument.new(@resource)
    end
end
