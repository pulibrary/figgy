class OcrRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ocr_request, only: [:destroy]

  def index
    @ocr_requests = OcrRequest.all
  end


  def destroy
    @ocr_request.destroy
    respond_to do |format|
      format.html { redirect_to ocr_requests_url, notice: 'Ocr request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def upload_file
    @ocr_request = OcrRequest.new(ocr_request_params)
    if @ocr_request.save
      render status: :ok, json: { message: "uploaded" }
    else
      render status: :unprocessable_entity, json: @ocr_request.errors
    end
  end

  private

    def set_ocr_request
      @ocr_request = OcrRequest.find(params[:id])
    end

    def ocr_request_params
      {
        filename: params["file"].original_filename,
        state: "enqueued",
        user_id: current_user.id,
        pdf: params["file"]
      }
    end

  # def show
  # end
  # def new
  #   @ocr_request = OcrRequest.new
  # end
  # def edit
  # end
  # def create
  #   @ocr_request = OcrRequest.new(ocr_request_params)
  #
  #   respond_to do |format|
  #     if @ocr_request.save
  #       format.html { redirect_to @ocr_request, notice: 'Ocr request was successfully created.' }
  #       format.json { render :show, status: :created, location: @ocr_request }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @ocr_request.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  # def update
  #   respond_to do |format|
  #     if @ocr_request.update(ocr_request_params)
  #       format.html { redirect_to @ocr_request, notice: 'Ocr request was successfully updated.' }
  #       format.json { render :show, status: :ok, location: @ocr_request }
  #     else
  #       format.html { render :edit }
  #       format.json { render json: @ocr_request.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
end
