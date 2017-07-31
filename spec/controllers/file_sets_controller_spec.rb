# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FileSetsController do
  let(:persister) { Valkyrie.config.metadata_adapter.persister }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:user) { FactoryGirl.create(:admin) }
  before do
    sign_in user if user
  end
  describe "PATCH /file_sets/id" do
    it "can update a file set" do
      file_set = FactoryGirl.create_for_repository(:file_set)
      patch :update, params: { id: file_set.id.to_s, file_set: { title: ["Second"] } }

      file_set = query_service.find_by(id: file_set.id)
      expect(file_set.title).to eq ["Second"]
    end
  end

  describe "GET /concern/file_sets/:id/edit" do
    render_views
    it "renders" do
      file_set = FactoryGirl.create_for_repository(:file_set)

      expect { get :edit, params: { id: file_set.id.to_s } }.not_to raise_error
    end
  end
end
