# frozen_string_literal: true

require "rails_helper"

describe ProxyFileSetsController, type: :controller do
  with_queue_adapter :inline

  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
  let(:factory) { :proxy_file_set }

  before do
    sign_in user if user
  end

  describe "destroy" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      it_behaves_like "an access controlled destroy request"
    end
    it "can delete a resource" do
      resource = FactoryBot.create_for_repository(factory)
      delete :destroy, params: {id: resource.id.to_s}

      expect(response).to redirect_to root_path
      expect { query_service.find_by(id: resource.id) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
