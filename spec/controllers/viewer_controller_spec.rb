# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewerController do
  render_views

  describe "#index" do
    it "generates a hidden login container" do
      get :index

      expect(response.body).to have_selector "#login", text: "Princeton Users: Log in to View", visible: false
    end
  end
end
