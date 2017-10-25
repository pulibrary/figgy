RSpec.shared_examples "an access controlled new request" do
  context "when not logged in" do
    let(:user) { nil }
    it "redirects CanCan::AccessDenied error to login" do
      get :new
      expect(response).to redirect_to('/users/auth/cas')
    end
  end
  context "when not an admin" do
    let(:user) { FactoryGirl.create(:user) }
    it "redirects CanCan::AccessDenied error to root path" do
      get :new
      expect(response).to redirect_to root_path
    end
  end
end
