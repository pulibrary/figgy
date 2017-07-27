# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ScannedResourcesController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  before do
    sign_in user if user
  end
  context "when an admin" do
    let(:user) { FactoryGirl.create(:admin) }
    describe "GET /scanned_resources/:id/file_manager" do
      it "sets the record and children variables" do
        child = FactoryGirl.create_for_repository(:file_set)
        parent = FactoryGirl.create_for_repository(:scanned_resource, member_ids: child.id)

        get :file_manager, params: { id: parent.id }

        expect(assigns(:change_set).id).to eq parent.id
        expect(assigns(:children).map(&:id)).to eq [child.id]
      end
    end
  end
end
