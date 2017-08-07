# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Scanned Resources Management" do
  let(:user) { FactoryGirl.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  before do
    sign_in user if user
  end
  describe "new" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        expect { get "/concern/scanned_resources/new" }.to raise_error CanCan::AccessDenied
      end
    end
    it "has a form for creating scanned resources" do
      collection = FactoryGirl.create_for_repository(:collection)

      get "/concern/scanned_resources/new"
      expect(response.body).to have_field "Title"
      expect(response.body).to have_field "Source Metadata ID"
      expect(response.body).to have_field "scanned_resource[refresh_remote_metadata]"
      expect(response.body).to have_field "Rights Statement"
      expect(response.body).to have_field "Rights Note"
      expect(response.body).to have_field "Local identifier"
      expect(response.body).to have_field "Holding Location"
      expect(response.body).to have_field "Portion Note"
      expect(response.body).to have_field "Navigation Date"
      expect(response.body).to have_select "Collections", name: "scanned_resource[member_of_collection_ids][]", options: ["", collection.title.first]
      expect(response.body).to have_select "Rights Statement", name: "scanned_resource[rights_statement]", options: [""] + ControlledVocabulary.for(:rights_statement).all.map(&:label)
      expect(response.body).to have_select "PDF Type", name: "scanned_resource[pdf_type]", options: ["Color PDF", "Grayscale PDF", "Bitonal PDF", "No PDF"]
      expect(response.body).to have_select "Holding Location", name: "scanned_resource[holding_location]", options: [""] + ControlledVocabulary.for(:holding_location).all.map(&:label)
      expect(response.body).to have_checked_field "Private"
      expect(response.body).to have_button "Save"
    end
  end

  describe "structure" do
    context "when not logged in" do
      let(:user) { nil }
      it "throws a CanCan::AccessDenied error" do
        scanned_resource = FactoryGirl.create_for_repository(:scanned_resource)

        expect { get structure_scanned_resource_path(scanned_resource) }.to raise_error CanCan::AccessDenied
      end
    end
    context "when a scanned resource doesn't exist" do
      it "raises an error" do
        expect { get structure_scanned_resource_path(id: "banana") }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
    context "when it does exist" do
      it "renders a structure editor form" do
        file_set = FactoryGirl.create_for_repository(:file_set)
        scanned_resource = FactoryGirl.create_for_repository(
          :scanned_resource,
          member_ids: file_set.id,
          logical_structure: [
            { label: 'testing', nodes: [{ label: 'Chapter 1', nodes: [{ proxy: file_set.id }] }] }
          ]
        )

        get structure_scanned_resource_path(scanned_resource)

        expect(response.body).to have_selector "li[data-proxy='#{file_set.id}']"
        expect(response.body).to have_field('label', with: 'Chapter 1')
        expect(response.body).to have_link scanned_resource.title.first, href: solr_document_path(id: "id-#{scanned_resource.id}")
      end
    end
  end

  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
