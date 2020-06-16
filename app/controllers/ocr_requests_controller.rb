# frozen_string_literal: true

class OcrRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ocr_request, only: [:destroy, :show]

  def index
    @ocr_requests = OcrRequest.all
  end

  def destroy
    @ocr_request.destroy
    respond_to do |format|
      format.html { redirect_to ocr_requests_url, notice: "Ocr request was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def upload_file
    @ocr_request = OcrRequest.new(ocr_request_params)
    if @ocr_request.save
      PdfOcrJob.perform_later(resource: @ocr_request, out_path: ocr_out_file)
      render status: :ok, json: { message: "uploaded" }
    else
      render status: :unprocessable_entity, json: @ocr_request.errors
    end
  end

  private

    def ocr_out_file
      out_dir = ENV["OCR_OUT_PATH"] || temp_ocr_out_dir
      File.join(out_dir, @ocr_request.filename)
    end

    def temp_ocr_out_dir
      path = Rails.root.join("tmp", "ocr_out")
      FileUtils.mkdir_p(path).first
    end

    def ocr_request_params
      {
        filename: params["file"].original_filename,
        state: "enqueued",
        user_id: current_user.id,
        pdf: params["file"]
      }
    end

    def set_ocr_request
      @ocr_request = OcrRequest.find(params[:id])
    end
end
