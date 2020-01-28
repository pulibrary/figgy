# frozen_string_literal: true
require "rails_helper"

RSpec.describe Migration::SovietPostersRepair do
  let(:change_set_persister) { EphemeraFoldersController.change_set_persister }
  ControlledVocabulary.for(:visibility).all.map(&:value).each do |visibility|
    it "repairs the #{visibility} value that somehow got messed up" do
      # Now only visibility is broken.
      resource = FactoryBot.create_for_repository(:ephemera_folder, visibility: visibility)
      # A decorated resource got persisted.
      resource = resource.decorate
      change_set = DynamicChangeSet.new(resource)
      change_set_persister.save(change_set: change_set)
      output = change_set_persister.query_service.find_by(id: resource.id)
      expect(output.visibility[0][:html_safe]).to eq true

      described_class.call

      output = change_set_persister.query_service.find_by(id: resource.id)
      expect(output.visibility[0]).to eq visibility
    end
  end
end
