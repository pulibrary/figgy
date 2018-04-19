# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ArchivalMediaCollectionsController do
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end

  it "creates the right kind of resource" do
    expect(described_class.resource_class).to eq ArchivalMediaCollection
  end

  context "when an admin" do
    let(:user) { FactoryBot.create(:admin) }

    describe "GET /collections/new" do
      render_views
      it "renders a new record form" do
        get :new

        expect(response).to render_template("valhalla/base/_form")
      end
    end
  end
end
