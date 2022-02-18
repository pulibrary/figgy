# frozen_string_literal: true

require "rails_helper"

RSpec.describe NumismaticsDashboardController, type: :controller do
  describe "#show" do
    context "when user is an admin" do
      let(:user) { FactoryBot.create(:admin) }
      it "returns the numismatics home page" do
        2.times { FactoryBot.create_for_repository(:numismatic_issue) }
        FactoryBot.create_for_repository(:numismatic_monogram)
        2.times { FactoryBot.create_for_repository(:numismatic_place) }
        10.times { FactoryBot.create_for_repository(:numismatic_firm) }

        get :show
        expect(assigns(:issues)).to eq 2
        expect(assigns(:monograms)).to eq 1
        expect(assigns(:places)).to eq 2
        expect(assigns(:people)).to eq 0
        expect(assigns(:firms)).to eq 10
        expect(assigns(:accessions)).to eq 0
      end
    end
    context "when user is staff" do
      let(:user) { FactoryBot.create(:staff) }
      it "returns the numismatics home page" do
        2.times { FactoryBot.create_for_repository(:numismatic_issue) }
        FactoryBot.create_for_repository(:numismatic_monogram)
        2.times { FactoryBot.create_for_repository(:numismatic_place) }
        10.times { FactoryBot.create_for_repository(:numismatic_firm) }

        get :show
        expect(assigns(:issues)).to eq 2
        expect(assigns(:monograms)).to eq 1
        expect(assigns(:places)).to eq 2
        expect(assigns(:people)).to eq 0
        expect(assigns(:firms)).to eq 10
        expect(assigns(:accessions)).to eq 0
      end
    end
    context "when user is a campus_patron" do
      let(:user) { FactoryBot.create(:campus_patron) }
      it "does not display " do
        get :show
        expect(flash[:alert]).to have_content "You are not authorized to access this page"
      end
    end
  end
end
