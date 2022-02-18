# frozen_string_literal: true

require "rails_helper"

RSpec.feature "OCR Requests" do
  let(:user) { FactoryBot.create(:staff) }
  let(:ocr_request) { FactoryBot.create(:ocr_request) }

  before do
    sign_in user
    ocr_request
  end

  context "when an authorized user vists the ocr requests page" do
    it "displays a file uploader and requests table" do
      visit ocr_requests_path
      expect(page).to have_css "file-uploader"
      expect(page).to have_css "table tr td", text: ocr_request.filename
    end
  end
end
