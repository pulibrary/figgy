# lazy define (i.e. with `let`) in the including spec:
#   factory 
RSpec.shared_examples "an access controlled edit request" do
  context "when not logged in" do
    let(:user) { nil }
    it "redirects CanCan::AccessDenied error to login" do
      resource = FactoryGirl.create_for_repository(factory)
      get :edit, params: { id: resource.id.to_s }
      expect(response).to redirect_to('/users/auth/cas')
    end
  end
  context "when not an admin" do
    let(:user) { FactoryGirl.create(:user) }
    it "redirects CanCan::AccessDenied error to root path" do
      resource = FactoryGirl.create_for_repository(factory)
      get :edit, params: { id: resource.id.to_s }
      expect(response).to redirect_to root_path
    end
  end
end
