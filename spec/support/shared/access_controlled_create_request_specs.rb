# lazy define (i.e. with `let`) params in the including spec
RSpec.shared_examples "an access controlled create request" do
  context "when not logged in" do
    let(:user) { nil }
    it "redirects CanCan::AccessDenied error to login" do
      post :create, params: params
      expect(response).to redirect_to('/users/auth/cas')
    end
  end
  context "when not an admin" do
    let(:user) { FactoryGirl.create(:user) }
    it "redirects CanCan::AccessDenied error to root path" do
      post :create, params: params
      expect(response).to redirect_to root_path
    end
  end
end
