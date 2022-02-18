# frozen_string_literal: true

require "rails_helper"

RSpec.describe EphemeraFieldDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:ephemera_field) }
  describe "decoration" do
    it "decorates an EphemeraField" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it "does not manage files" do
    expect(decorator.manageable_files?).to be false
  end
  it "does not order files" do
    expect(decorator.orderable_files?).to be false
  end
  it "does not manage structures" do
    expect(decorator.manageable_structure?).to be false
  end
  it "exposes the label for a controlled name" do
    expect(resource.decorate.name_label).to eq "EphemeraFolder.language"
  end
  it "exposes the title as the label" do
    expect(resource.decorate.title).to eq resource.decorate.name_label
  end
  it "exposes markup for the field name" do
    expect(resource.decorate.rendered_name).not_to be_empty
    expect(resource.decorate.rendered_name.first).to match(/EphemeraFolder\.language/)
  end
  context "within a project" do
    let(:resource) { FactoryBot.create_for_repository(:ephemera_field) }
    before do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      project = FactoryBot.build(:ephemera_project)
      project.member_ids = [resource.id]
      adapter.persister.save(resource: project)
    end

    it "retrieves the title of parents" do
      expect(resource.decorate.projects.to_a).not_to be_empty
      expect(resource.decorate.projects.to_a.first).to be_a EphemeraProject
    end
  end
  context "when a child of another vocabulary" do
    let(:vocab) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "test parent vocabulary") }
    let(:resource) do
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      res = FactoryBot.build(:ephemera_field)
      res.member_of_vocabulary_id = vocab.id
      adapter.persister.save(resource: res)
    end

    it "retrieves the parent vocabulary" do
      expect(resource.decorate.vocabulary).to be_a EphemeraVocabulary
      expect(resource.decorate.vocabulary.label).to eq "test parent vocabulary"
    end

    it "exposes the label for the vocabulary" do
      expect(resource.decorate.vocabulary_label).to eq resource.decorate.vocabulary.label
    end
  end
end
