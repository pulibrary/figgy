# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe PlaylistsController do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:valid_params) do
      {
        label: ["Test Playlist"],
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        visibility: "restricted"
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :playlist }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :playlist }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :playlist }
      let(:extra_params) { { playlist: { title: ["My Playlist"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
end
