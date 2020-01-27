# frozen_string_literal: true
require "rails_helper"

RSpec.describe Migration::SovietPostersRepair do
  let(:change_set_persister) { EphemeraFoldersController.change_set_persister }
  it "repairs the controlled vocabulary values that somehow got messed up" do
    # Messed up ones would be Genre, Geographic Subject, Geographic Origin,
    # Language, Subject
    term = FactoryBot.create_for_repository(:ephemera_term)
    resource = FactoryBot.create_for_repository(:ephemera_folder, genre: term.id, geographic_origin: term.id, language: term.id, subject: term.id, geo_subject: term.id)
    # A decorated resource got persisted.
    resource = resource.decorate
    change_set = DynamicChangeSet.new(resource)
    change_set_persister.save(change_set: change_set)
    output = change_set_persister.query_service.find_by(id: resource.id)
    expect(output.genre[0][:":label"]).to eq "test term"

    described_class.call

    output = change_set_persister.query_service.find_by(id: resource.id)
    expect(output.genre[0]).to eq term.id
    expect(output.geo_subject[0]).to eq term.id
    expect(output.geographic_origin[0]).to eq term.id
    expect(output.language[0]).to eq term.id
    expect(output.subject[0]).to eq term.id
  end
end
