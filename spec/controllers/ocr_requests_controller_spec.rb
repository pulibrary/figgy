# frozen_string_literal: true
require "rails_helper"

RSpec.describe OCRRequestsController, type: :controller do
  with_queue_adapter :inline
  let(:user) { FactoryBot.create(:staff) }
  let(:valid_params) do
    {
      filename: "requested.pdf",
      note: "request note"
    }
  end

  before do
    sign_in user
  end

  describe "GET #index" do
    it "sets ocr_requests and returns a success response" do
      OcrRequest.create! valid_params
      get :index
      expect(assigns(:ocr_requests).count).to eq 1
      expect(response).to be_successful
    end

    context "when user is a campus_patron" do
      let(:user) { FactoryBot.create(:campus_patron) }
      it "does not display " do
        get :index
        expect(flash[:alert]).to have_content "You are not authorized to access this page"
      end
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      ocr_request = OcrRequest.create! valid_params
      get :show, params: { id: ocr_request.to_param }
      expect(response).to be_successful
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested ocr_request" do
      ocr_request = OcrRequest.create! valid_params
      expect do
        delete :destroy, params: { id: ocr_request.to_param }
      end.to change(OcrRequest, :count).by(-1)
    end

    it "redirects to the ocr_requests list" do
      ocr_request = OcrRequest.create! valid_params
      delete :destroy, params: { id: ocr_request.to_param }
      expect(response).to redirect_to(ocr_requests_url)
    end
  end

  describe "POST #upload_file" do
    let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }

    before do
      allow(PdfOcrJob).to receive(:perform_later)
    end

    it "creates an OcrRequest resource and initiates an OCR job" do
      post :upload_file, params: { file: file }
      ocr_request = OcrRequest.all.first
      expect(ocr_request.filename).to eq file.original_filename
      expect(ocr_request.state).to eq "Enqueued"
      expect(PdfOcrJob).to have_received(:perform_later)
    end

    context "when an ocr request resource can't be created" do
      let(:ocr_request) { instance_double(OcrRequest) }

      before do
        allow(OcrRequest).to receive(:new).and_return(ocr_request)
        allow(ocr_request).to receive(:save).and_return(false)
        allow(ocr_request).to receive(:errors).and_return("errors")
      end

      it "returns errors" do
        post :upload_file, params: { file: file }
        expect(response.body).to eq "errors"
        expect(response).not_to be_successful
      end
    end
  end
end
