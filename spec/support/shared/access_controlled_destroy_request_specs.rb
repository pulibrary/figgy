# lazy define (i.e. with `let`) in the including spec:
#   factory
RSpec.shared_examples "an access controlled destroy request" do
  context "when not logged in" do
    let(:user) { nil }
    it "redirects CanCan::AccessDenied error to login" do
      resource = FactoryBot.create_for_repository(factory)
      delete :destroy, params: { id: resource.id.to_s }
      expect(response).to redirect_to('/users/auth/cas')
    end
  end
  context "when not an admin" do
    let(:user) { FactoryBot.create(:user) }
    it "redirects CanCan::AccessDenied error to root path" do
      resource = FactoryBot.create_for_repository(factory)
      delete :destroy, params: { id: resource.id.to_s }
      expect(response).to redirect_to root_path
    end
  end
end
