require 'rails_helper'

RSpec.describe DashboardController, type: :controller do

  describe "GET #fixity" do
    it "returns http success" do
      get :fixity
      expect(response).to have_http_status(:success)
    end
  end

end
