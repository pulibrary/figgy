# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::PeopleController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:user) { FactoryBot.create(:admin) }
    let(:valid_params) do
      {
        name1: "Marcus",
        name2: "Aurelius"
      }
    end
    let(:invalid_params) do
      {
        title: nil
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
    it "creates a person" do
      FactoryBot.create_for_repository(:numismatic_person)
      post :create, params: {numismatics_person: valid_params}
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/people"
      person = query_service.find_all_of_model(model: Numismatics::Person).find { |n| n["name1"] == ["Marcus"] }
      expect(person.depositor).to eq [user.uid]
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_person }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_person }
      it_behaves_like "an access controlled edit request"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_person }
      let(:extra_params) { {numismatic_person: {name1: ["Ceasar"]}} }
      it_behaves_like "an access controlled update request"
    end
    it "saves and redirects" do
      numismatic_person = FactoryBot.create_for_repository(:numismatic_person)
      patch :update, params: {id: numismatic_person.id.to_s, numismatics_person: {name1: ["Ceasar"]}}
      expect(response).to be_redirect
      expect(response.location).to start_with "http://test.host/concern/numismatics/people"
    end
  end
  describe "index" do
    context "when they have permission" do
      let(:user) { FactoryBot.create(:admin) }
      render_views
      it "has lists all numismatic people" do
        FactoryBot.create_for_repository(:numismatic_person)

        get :index
        expect(response.body).to have_content "name1"
      end
    end
  end
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
