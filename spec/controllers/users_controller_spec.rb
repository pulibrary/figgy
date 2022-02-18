# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }

  before do
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      User.create! uid: "asdf", email: "asdf@princeton.edu", provider: "cas"
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new User" do
        expect do
          post :create, params: {user: {uid: "asdf"}}
        end.to change(User, :count).by(1)
      end

      it "redirects to the user list" do
        post :create, params: {user: {uid: "asdf"}}
        expect(response).to redirect_to(users_path)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {user: {name: "bob"}}
        expect(response).not_to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested user" do
      user = User.create! uid: "asdf", email: "asdf@princeton.edu", provider: "cas"
      expect do
        delete :destroy, params: {id: user.to_param}
      end.to change(User, :count).by(-1)
    end

    it "redirects to the user list" do
      user = User.create! uid: "asdf", email: "asdf@princeton.edu", provider: "cas"
      delete :destroy, params: {id: user.to_param}
      expect(response).to redirect_to(users_url)
    end
  end
end
