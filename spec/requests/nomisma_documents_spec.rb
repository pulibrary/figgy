# frozen_string_literal: true
require "rails_helper"

RSpec.describe "NomismaDocumets requests", type: :request do
  with_queue_adapter :inline
  let(:user) { FactoryBot.create(:staff) }
  let(:valid_params) do
    {
      state: "complete",
      rdf: "rdf content"
    }
  end

  before do
    sign_in user
  end

  describe "DELETE /nomisma/:id" do
    it "destroys the requested nomisma_document" do
      nomisma_document = NomismaDocument.create! valid_params
      expect do
        delete "/nomisma/#{nomisma_document.to_param}"
      end.to change(NomismaDocument, :count).by(-1)
    end

    context "when not an authorized user" do
      let(:user) { FactoryBot.create(:campus_patron) }

      it "does not destory the requested nomisma_document" do
        nomisma_document = NomismaDocument.create! valid_params
        expect do
          delete "/nomisma/#{nomisma_document.to_param}"
        end.to change(NomismaDocument, :count).by(0)
      end
    end
  end

  describe "GET /nomisma/:id/princeton-nomisma" do
    context "when requesting a file with an rdf extension" do
      it "returns the rdf document as xml" do
        nomisma_document = NomismaDocument.create! valid_params
        get "/nomisma/#{nomisma_document.to_param}/princeton-nomisma.rdf"
        expect(response.status).to eq 200
        expect(response.body).to eq "rdf content"
      end
    end

    context "when requesting a file without an rdf extension" do
      it "returns a 501 status code" do
        nomisma_document = NomismaDocument.create! valid_params
        get "/nomisma/#{nomisma_document.to_param}/princeton-nomisma"
        expect(response.status).to eq 501
      end
    end
  end

  describe "GET /nomisma/void" do
    context "when requesting a void document an rdf extension" do
      it "returns the rdf document as xml" do
        nomisma_document = NomismaDocument.create! valid_params
        get "/nomisma/void.rdf"
        expect(response.status).to eq 200
        expect(response.body).to include("<dcterms:title>The Princeton University Numismatic Collection</dcterms:title>")
        expect(response.body).to include("nomisma/#{nomisma_document.to_param}/princeton-nomisma.rdf")
      end
    end

    context "when requesting a file without an rdf extension" do
      it "returns a 501 status code" do
        get "/nomisma/void"
        expect(response.status).to eq 501
      end
    end
  end

  describe "POST /nomisma/generate" do
    let(:coin) { FactoryBot.create_for_repository(:coin, state: "complete", identifier: "ark:/88435/testcoin") }
    let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, state: "complete", denomination: nil, member_ids: [coin.id]) }

    before do
      issue
      coin
    end

    it "creates a new NomismaDocument with rdf" do
      expect do
        post "/nomisma/generate"
      end.to change(NomismaDocument, :count).by(1)
      nomisma_document = NomismaDocument.all.first

      expect(nomisma_document.state).to eq "complete"
      expect(nomisma_document.rdf).to include("rdf:about='http://arks.princeton.edu/ark:/88435/testcoin'")
    end

    context "when an exisiting in-process NomismaDocument exists" do
      it "does not create a new one" do
        NomismaDocument.create!({ state: "processing" })
        expect do
          post "/nomisma/generate"
        end.to change(NomismaDocument, :count).by(0)
      end
    end
  end
end
