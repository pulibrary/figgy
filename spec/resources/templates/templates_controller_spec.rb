# frozen_string_literal: true
require "rails_helper"

RSpec.describe TemplatesController, type: :controller do
  let(:user) { FactoryBot.create(:staff) }
  describe "#new" do
    before do
      sign_in user if user
    end
    render_views
    it "renders a form for the given model with no required fields" do
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary)
      subject_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Subjects")
      toy_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Toys", member_of_vocabulary_id: subject_vocabulary.id)
      FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: toy_vocabulary.id, label: "Trains")
      field = FactoryBot.create_for_repository(:ephemera_field, field_name: "5", member_of_vocabulary_id: subject_vocabulary.id)
      FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: vocabulary.id, label: "Test")
      field2 = FactoryBot.create_for_repository(:ephemera_field, field_name: "1", member_of_vocabulary_id: vocabulary.id)
      project = FactoryBot.create_for_repository(:ephemera_project, member_ids: [field.id, field2.id])

      get :new, params: { model_class: "EphemeraFolder", ephemera_project_id: project.id.to_s }

      expect(response.body).to have_field "template[title]"
      expect(response.body).to have_select "Language", options: ["Test"]
      expect(response.body).to have_select "Subject"
    end
  end
  describe "#destroy" do
    before do
      sign_in FactoryBot.create(:staff)
    end
    it "deletes a template" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      template = FactoryBot.create_for_repository(:template)

      delete :destroy, params: { ephemera_project_id: project.id.to_s, id: template.id.to_s }

      expect { query_service.find_by(id: template.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      expect(response).to redirect_to solr_document_path(id: project.id)
    end
  end
  describe "#create" do
    before do
      sign_in user if user
    end
    it "can create a template with a child set of properties" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      post :create, params: {
        ephemera_project_id: project.id.to_s,
        template:
        {
          title: "Test Template",
          model_class: "EphemeraFolder",
          child_change_set_attributes: {
            language: "English"
          }
        }
      }

      template = TemplateChangeSet.new(query_service.find_all_of_model(model: Template).to_a.first)
      template.prepopulate!
      expect(template.child_change_set.language).to eq ["English"]
      expect(template.parent_id).to eq project.id
    end
    it "re-renders the form if no title is added" do
      project = FactoryBot.create_for_repository(:ephemera_project)
      post :create, params: {
        ephemera_project_id: project.id.to_s,
        template:
        {
          title: ""
        }
      }
      expect(response).to render_template :new
    end
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end
end
