# frozen_string_literal: true
require "rails_helper"

describe IngestEphemeraCSV do
  subject(:service) { described_class.new(project.id, mdata, imgdir, change_set_persister, logger) }
  let(:project) do
    FactoryBot.create_for_repository(:ephemera_project,
                                     title: "South Asian Ephemera",
                                     id: Valkyrie::ID.new("project_number_1"))
  end
  let(:collection) do
    FactoryBot.create_for_repository(:collection,
                                     title: "Dissidents and Activists in Sri Lanka, 1960s to 1990")
  end
  let(:mdata) { Rails.root.join("spec", "fixtures", "files", "sae_ephemera_invalid.csv") }
  let(:imgdir) { Rails.root.join("spec", "fixtures", "ephemera", "sae") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
  let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:logger) { Logger.new(nil) }

  before do
    collection
    politics_and_government = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                               label: "Politics and government")

    human_and_civil_rights = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                              label: "Human and civil rights")

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Human rights advocacy",
                                     member_of_vocabulary_id: human_and_civil_rights.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Civil Rights",
                                     member_of_vocabulary_id: human_and_civil_rights.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Constitutions",
                                     member_of_vocabulary_id: politics_and_government.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Politics and government",
                                     member_of_vocabulary_id: politics_and_government.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: "Decentralization in government",
                                     member_of_vocabulary_id: politics_and_government.id)

    languages = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                                 label: "LAE Languages")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Sinhala | Sinhalese"],
                                     code: ["sin"],
                                     member_of_vocabulary_id: languages.id)
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Tamil"],
                                     code: ["tam"],
                                     member_of_vocabulary_id: languages.id)

    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["English | Eng"],
                                     code: ["eng"],
                                     member_of_vocabulary_id: languages.id)

    areas = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                             label: "LAE Geographic Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Sri Lanka"],
                                     member_of_vocabulary_id: areas.id)

    areas2 = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                              label: "LAE Areas")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Sri Lanka"],
                                     member_of_vocabulary_id: areas2.id)

    genres = FactoryBot.create_for_repository(:ephemera_vocabulary,
                                              label: "LAE Genres")
    FactoryBot.create_for_repository(:ephemera_term,
                                     label: ["Pamphlet"],
                                     member_of_vocabulary_id: genres.id)
  end
  # rubocop:disable Metrics/LineLength


  context "validate" do
    it "handles validation" do
      output = service.validate
      expect(output).to be_falsey
      expect(service.validation_errors.count).to eq(1)
    end
  end
end
