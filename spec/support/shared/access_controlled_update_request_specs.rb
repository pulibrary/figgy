# lazy define (i.e. with `let`) in the including spec:
#  factory 
#  extra_params (beyond id)
RSpec.shared_examples "an access controlled update request" do
  context "when not logged in" do
    let(:user) { nil }
    it "redirects CanCan::AccessDenied error to login" do
      resource = FactoryBot.create_for_repository(factory)
      params = { id: resource.id.to_s }.merge(extra_params)
      patch :update, params: params
      expect(response).to redirect_to('/users/auth/cas')
    end
  end
  context "when not an admin" do
    let(:user) { FactoryBot.create(:user) }
    it "redirects CanCan::AccessDenied error to root path" do
      resource = FactoryBot.create_for_repository(factory)
      params = { id: resource.id.to_s }.merge(extra_params)
      patch :update, params: params
      expect(response).to redirect_to root_path
    end
  end
end
