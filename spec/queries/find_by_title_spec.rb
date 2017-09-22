# frozen_string_literal: true
require 'rails_helper'

RSpec.describe FindByTitle do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:project) { FactoryGirl.create_for_repository(:ephemera_project, title: "Testing") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_title" do
    it "can find objects by a title string" do
      output = query.find_by_title(title: project.title.first).first
      expect(output.id).to eq project.id
    end
  end
end
